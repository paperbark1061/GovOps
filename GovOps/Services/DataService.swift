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
            if let companiesURL = Bundle.main.url(forResource: "companies", withExtension: "json"),
               let companiesData = try? Data(contentsOf: companiesURL),
               let companies = try? decoder.decode([Company].self, from: companiesData) {
                loadedCompanies = companies
            } else {
                loadErrors.append("companies.json")
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

    // MARK: - 3-Tier Company Matching Logic

    private static let companyKeywords: [String: [String]] = [
        "paxus": ["developer", "engineer", "analyst", "architect", "project manager", "test", "infrastructure", "cloud", "network", "security", "support", "devops", "data", "mobile", "software"],
        "hays": ["developer", "engineer", "analyst", "architect", "project manager", "test", "infrastructure", "cloud", "network", "security", "support", "devops", "data", "mobile", "software", "manager", "lead", "senior", "consultant", "cyber", "sap", "oracle", "java", ".net", "ux", "designer", "business analyst", "delivery"],
        "peoplebank": ["developer", "engineer", "analyst", "architect", "project manager", "test", "infrastructure", "cloud", "security", "devops", "data", "software", "lead", "senior", "consultant"],
        "deloitte": ["architect", "project manager", "manager", "lead", "senior", "consultant", "cyber", "security", "sap", "strategy", "program", "delivery", "advisory", "digital", "data", "cloud"],
        "dxc": ["developer", "engineer", "analyst", "sap", "consultant", "infrastructure", "cloud", "software", ".net", "java", "oracle", "mobile", "devops"],
        "nttdata": ["architect", "manager", "lead", "senior", "consultant", "analyst", "cyber", "security", "digital", "systems"],
        "accenture": ["developer", "engineer", "analyst", "architect", "project manager", "test", "infrastructure", "cloud", "security", "devops", "data", "mobile", "software", "manager", "lead", "senior", "consultant", "cyber", "sap", "oracle", "java", ".net", "ux", "designer", "digital", "delivery", "program"],
        "agiledigital": ["developer", "engineer", "data", "software", "cloud", "test", "mobile", "ux", "designer", "digital", "lead", "senior", "devops", ".net", "java", "oracle"],
        "atturra": ["developer", "engineer", "consultant", "sap", "infrastructure", "cloud", "software", ".net", "java", "oracle", "integration", "devops", "data", "network"],
        "harrisonmcmillan": ["analyst", "architect", "project manager", "manager", "lead", "senior", "consultant", "business analyst", "data", "test", "cyber", "security", "delivery", "program"],
        "troocoo": ["developer", "engineer", "analyst", "test", "data", "cyber", "security", "digital", "cloud", "software", "consultant", "lead", "senior", "devops", ".net", "java", "sap", "mobile", "infrastructure"],
        "gwgrecruitment": ["developer", "engineer", "analyst", "test", "data", "software", "lead", "senior", "infrastructure", "cloud", "security", "business analyst", "cyber"],
        "modis": ["developer", "engineer", "analyst", "test", "data", "software", "lead", "senior", "infrastructure", "cloud", "security", "business analyst", "sap", "project manager"],
        "equinix": ["infrastructure", "cloud", "network", "engineer", "data", "security"],
        "aws": ["developer", "engineer", "architect", "cloud", "infrastructure", "software", "devops", "data", "security", "lead", "senior"],
        "hpe": ["infrastructure", "cloud", "architect", "engineer", "security", "enterprise", "network", "data"],
        "randstad": ["developer", "engineer", "analyst", "architect", "project manager", "test", "infrastructure", "cloud", "security", "devops", "data", "mobile", "software", "lead", "senior", "business analyst", "sap", ".net", "java"],
        "roberthalf": ["developer", "engineer", "analyst", "architect", "project manager", "test", "data", "software", "lead", "senior", "business analyst", "manager", "consultant", "delivery", "cyber", "security", "sap", ".net", "java", "oracle", "devops"],
        "michaelpage": ["developer", "engineer", "analyst", "architect", "project manager", "test", "infrastructure", "cloud", "security", "devops", "data", "software", "lead", "senior", "business analyst", "sap", "manager", "delivery", "cyber"],
        "chandlermacleod": ["developer", "engineer", "analyst", "project manager", "test", "infrastructure", "cloud", "security", "devops", "data", "software", "lead", "senior", "business analyst", "sap", ".net", "java", "manager", "delivery", "program", "mobile"],
        "hudson": ["analyst", "architect", "project manager", "manager", "lead", "senior", "consultant", "business analyst", "delivery", "program", "test", "cyber", "security"],
        "manpowergroup": ["developer", "engineer", "analyst", "test", "infrastructure", "cloud", "security", "data", "software", "lead", "senior", "business analyst", "sap", ".net", "java", "project manager"],
        "capgemini": ["developer", "engineer", "architect", "cloud", "data", "software", "digital", ".net", "java", "oracle", "mobile", "devops", "infrastructure", "ai"],
        "kpmg": ["architect", "project manager", "manager", "lead", "senior", "consultant", "cyber", "security", "sap", "strategy", "program", "delivery", "advisory", "digital", "data", "cloud"],
        "ey": ["architect", "project manager", "manager", "lead", "senior", "consultant", "cyber", "security", "sap", "strategy", "program", "delivery", "advisory", "digital"],
        "pwc": ["architect", "project manager", "manager", "lead", "senior", "consultant", "cyber", "security", "strategy", "program", "delivery", "advisory", "digital", "data", "cloud"],
        "fujitsu": ["developer", "engineer", "infrastructure", "cloud", "software", ".net", "java", "oracle", "devops", "data", "application"],
        "infosys": ["developer", "engineer", "cloud", "software", "digital", ".net", "java", "data", "application", "devops", "infrastructure"],
        "wipro": ["developer", "engineer", "cloud", "software", "digital", ".net", "java", "data", "infrastructure", "devops", "application"],
        "cognizant": ["developer", "engineer", "cloud", "software", "digital", ".net", "java", "data", "infrastructure", "devops", "application"],
        "leidos": ["developer", "engineer", "analyst", "architect", "infrastructure", "cloud", "security", "devops", "data", "software", "lead", "senior", "cyber", "defence"],
        "thales": ["engineer", "infrastructure", "security", "cloud", "data", "software", "lead", "senior", "cyber", "defence", "digital", "network"],
        "datacom": ["developer", "engineer", "infrastructure", "cloud", "software", ".net", "java", "devops", "data", "application", "managed"],
        "dialog": ["consultant", "data", "digital", "analyst", "infrastructure", "cloud", "engineer", "lead", "senior", "sap", "transformation"],
        "unisys": ["infrastructure", "cloud", "enterprise", "engineer", "digital", "security", "data", "network"],
        "kinexus": ["developer", "engineer", "analyst", "test", "data", "software", "lead", "senior", "infrastructure", "cloud", "security", "business analyst", "sap", ".net", "java", "project manager", "devops"],
        "finite": ["developer", "engineer", "analyst", "test", "data", "software", "lead", "senior", "infrastructure", "cloud", "security", "business analyst", "sap", ".net", "java", "project manager", "devops", "mobile"],
        "aurec": ["developer", "engineer", "analyst", "test", "data", "software", "lead", "senior", "infrastructure", "cloud", "security", "business analyst", "sap", ".net", "java", "project manager", "devops"],
        "encore": ["developer", "engineer", "analyst", "test", "data", "software", "lead", "senior", "infrastructure", "cloud", "security", "business analyst", "sap", ".net", "java", "project manager", "devops"],
        "frontiersi": ["developer", "engineer", "data", "software", "cloud", "spatial", "digital", "infrastructure", "lead", "senior", "devops"]
    ]

    /// Strong/specific keywords that indicate exact role match
    private static let strongKeywords: Set<String> = [
        "developer", "engineer", "architect", ".net", "java", "sap", "cyber", "security",
        "devops", "cloud", "infrastructure", "oracle", "test", "testing", "ux", "designer",
        "data", "analytics", "mobile", "network", "database"
    ]

    /// Generic keywords that indicate general capability
    private static let genericKeywords: Set<String> = [
        "manager", "lead", "senior", "consultant", "analyst", "delivery", "program", "digital"
    ]

    struct MatchingCaches {
        var all: [String: [String]]
        var exact: [String: [String]]
        var similar: [String: [String]]
        var capable: [String: [String]]
    }

    private static func computeAllMatching(opportunities: [Opportunity], companies: [Company]) -> MatchingCaches {
        var allCache: [String: [String]] = [:]
        var exactCache: [String: [String]] = [:]
        var similarCache: [String: [String]] = [:]
        var capableCache: [String: [String]] = [:]

        for opp in opportunities {
            let titleLower = opp.title.lowercased()
            var allIds: [String] = []
            var exactIds: [String] = []
            var similarIds: [String] = []
            var capableIds: [String] = []

            for company in companies {
                guard company.isAdvertising else { continue }
                let keywords = companyKeywords[company.id] ?? []

                var strongMatches = 0
                var genericMatches = 0

                for keyword in keywords {
                    if titleLower.contains(keyword) {
                        if strongKeywords.contains(keyword) {
                            strongMatches += 1
                        } else if genericKeywords.contains(keyword) {
                            genericMatches += 1
                        } else {
                            strongMatches += 1
                        }
                    }
                }

                let totalMatches = strongMatches + genericMatches

                if strongMatches >= 2 {
                    // Exact match: multiple strong keyword hits
                    exactIds.append(company.id)
                    allIds.append(company.id)
                } else if strongMatches == 1 || (genericMatches >= 2 && strongMatches >= 1) {
                    // Similar: some relevance
                    similarIds.append(company.id)
                    allIds.append(company.id)
                } else if totalMatches > 0 || !keywords.isEmpty {
                    // Capable: on panel with some capability
                    capableIds.append(company.id)
                    allIds.append(company.id)
                }
            }

            allCache[opp.id] = allIds
            exactCache[opp.id] = exactIds
            similarCache[opp.id] = similarIds
            capableCache[opp.id] = capableIds
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
