import Foundation
import Combine

class DataService: ObservableObject {
    static let shared = DataService()

    @Published var opportunities: [Opportunity] = []
    @Published var companies: [Company] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // Cached matching results
    private var matchingCache: [String: [String]] = [:]
    private var exactMatchCache: [String: [String]] = [:]
    private var similarMatchCache: [String: [String]] = [:]
    private var capableCache: [String: [String]] = [:]

    private init() {
        loadData()
    }

    func loadData() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
            let decoder = JSONDecoder()
            var allOpps: [Opportunity] = []
            var loadErrors: [String] = []

            let oppFiles = ["opportunities", "opportunities2", "opportunities3"]
            for fileName in oppFiles {
                if let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
                   let data = try? Data(contentsOf: url),
                   let opps = try? decoder.decode([Opportunity].self, from: data) {
                    allOpps.append(contentsOf: opps)
                } else {
                    loadErrors.append("\(fileName).json")
                }
            }

            var loadedCompanies: [Company] = []
            let compFiles = ["companies", "companies2", "companies3", "companies4"]
            for fileName in compFiles {
                if let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
                   let data = try? Data(contentsOf: url),
                   let comps = try? decoder.decode([Company].self, from: data) {
                    loadedCompanies.append(contentsOf: comps)
                } else {
                    loadErrors.append("\(fileName).json")
                }
            }

            // Compute all tiers of matching
            let allCaches = Self.computeAllMatching(opportunities: allOpps, companies: loadedCompanies)

            DispatchQueue.main.async {
                self.opportunities = allOpps
                self.companies = loadedCompanies
                self.matchingCache = allCaches.all
                self.exactMatchCache = allCaches.exact
                self.similarMatchCache = allCaches.similar
                self.capableCache = allCaches.capable
                self.isLoading = false

                if allOpps.isEmpty && loadedCompanies.isEmpty {
                    self.errorMessage = "No data files found. Missing: \(loadErrors.joined(separator: ", "))"
                } else {
                    self.errorMessage = nil
                }
            }
        }
    }

    func refreshData() {
        loadData()
    }

    // MARK: - Company Queries

    func getCompanies(forOpportunity opportunity: Opportunity) -> [Company] {
        let matchingIds = matchingCache[opportunity.id] ?? []
        return companies.filter { matchingIds.contains($0.id) }
    }

    func getExactMatchCompanies(forOpportunity opportunity: Opportunity) -> [Company] {
        let ids = exactMatchCache[opportunity.id] ?? []
        return companies.filter { ids.contains($0.id) }
    }

    func getSimilarMatchCompanies(forOpportunity opportunity: Opportunity) -> [Company] {
        let ids = similarMatchCache[opportunity.id] ?? []
        return companies.filter { ids.contains($0.id) }
    }

    func getCapableCompanies(forOpportunity opportunity: Opportunity) -> [Company] {
        let ids = capableCache[opportunity.id] ?? []
        return companies.filter { ids.contains($0.id) }
    }

    func getAdvertisingCompanies() -> [Company] {
        companies.filter { $0.isAdvertising }
    }

    // MARK: - 3-Tier Panel-Based Company Matching

    /// Maps opportunity categories/keywords to relevant panel names
    private static let panelCategoryMap: [String: [String]] = [
        "hardware": ["Hardware Marketplace"],
        "equipment": ["Hardware Marketplace"],
        "device": ["Hardware Marketplace"],
        "laptop": ["Hardware Marketplace"],
        "server": ["Hardware Marketplace"],
        "storage": ["Hardware Marketplace"],
        "printer": ["Hardware Marketplace"],
        "network": ["Hardware Marketplace", "Telecommunications Marketplace"],
        "cabling": ["Hardware Marketplace"],
        "telecom": ["Telecommunications Marketplace"],
        "voice": ["Telecommunications Marketplace"],
        "mobile": ["Telecommunications Marketplace", "Hardware Marketplace"],
        "satellite": ["Telecommunications Marketplace"],
        "internet": ["Telecommunications Marketplace"],
        "broadband": ["Telecommunications Marketplace"],
        "carriage": ["Telecommunications Marketplace"],
        "unified communications": ["Telecommunications Marketplace"],
        "contact centre": ["Telecommunications Marketplace"],
    ]

    /// Speciality keywords that indicate a company name match in an opportunity
    private static let nameMatchThreshold = 3

    struct MatchingCaches {
        var all: [String: [String]]
        var exact: [String: [String]]
        var similar: [String: [String]]
        var capable: [String: [String]]
    }

    /// Build a lookup of company name words for fuzzy matching
    private static func buildNameIndex(companies: [Company]) -> [String: [String]] {
        var index: [String: [String]] = [:]  // word -> [companyId]
        for company in companies {
            let words = company.name.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 3 }
            for word in words {
                index[word, default: []].append(company.id)
            }
        }
        return index
    }

    private static func computeAllMatching(opportunities: [Opportunity], companies: [Company]) -> MatchingCaches {
        var allCache: [String: [String]] = [:]
        var exactCache: [String: [String]] = [:]
        var similarCache: [String: [String]] = [:]
        var capableCache: [String: [String]] = [:]

        // Pre-compute: companies by panel name
        var companiesByPanel: [String: Set<String>] = [:]
        for company in companies {
            if let panels = company.panels {
                for panel in panels where panel.isActive {
                    companiesByPanel[panel.panelName, default: []].insert(company.id)
                }
            }
        }

        // Pre-compute: name word index for company name matching
        let nameIndex = buildNameIndex(companies: companies)

        // All DMP2 company IDs (the largest pool — "capable" tier)
        let dmp2Ids = companiesByPanel["Digital Marketplace Panel 2"] ?? []

        for opp in opportunities {
            let titleLower = opp.title.lowercased()
            let titleWords = titleLower
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 3 }
            var exactIds: Set<String> = []
            var similarIds: Set<String> = []
            var capableIds: Set<String> = []

            // Tier 1 — Exact: company name appears in opportunity title/buyer
            let searchText = "\(opp.title) \(opp.buyer)".lowercased()
            for company in companies {
                let companyWords = company.name.lowercased()
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .filter { $0.count >= 3 }
                guard companyWords.count > 0 else { continue }
                let matchCount = companyWords.filter { searchText.contains($0) }.count
                // If most of the company name words appear in the opportunity text
                if matchCount >= min(nameMatchThreshold, max(1, companyWords.count - 1)) && matchCount >= 2 {
                    exactIds.insert(company.id)
                }
            }

            // Tier 2 — Similar: company is on a panel relevant to this opportunity's category
            for (keyword, panelNames) in panelCategoryMap {
                if titleLower.contains(keyword) {
                    for panelName in panelNames {
                        if let panelCompanyIds = companiesByPanel[panelName] {
                            similarIds.formUnion(panelCompanyIds)
                        }
                    }
                }
            }
            // Remove any already in exact
            similarIds.subtract(exactIds)

            // Tier 3 — Capable: on any active panel (DMP2 is the big pool)
            capableIds = dmp2Ids
            capableIds.subtract(exactIds)
            capableIds.subtract(similarIds)

            let allIds = Array(exactIds) + Array(similarIds) + Array(capableIds.prefix(50))

            allCache[opp.id] = allIds
            exactCache[opp.id] = Array(exactIds)
            similarCache[opp.id] = Array(similarIds)
            capableCache[opp.id] = Array(capableIds.prefix(50))
        }

        return MatchingCaches(all: allCache, exact: exactCache, similar: similarCache, capable: capableCache)
    }

    enum DataLoadError: LocalizedError {
        case fileNotFound(String)
        case decodingError

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let filename):
                return "\(filename) file not found"
            case .decodingError:
                return "Failed to decode JSON data"
            }
        }
    }
}
