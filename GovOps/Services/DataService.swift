import Foundation
import Combine

class DataService: ObservableObject {
    static let shared = DataService()

    @Published var opportunities: [Opportunity] = []
    @Published var companies: [Company] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // Cached matching results: opportunity ID -> [company ID]
    private var matchingCache: [String: [String]] = [:]

    private init() {
        loadData()
    }

    func loadData() {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) {
            do {
                // Load opportunities from three files
                let decoder = JSONDecoder()
                var allOpps: [Opportunity] = []

                let oppFiles = ["opportunities", "opportunities2", "opportunities3"]
                for fileName in oppFiles {
                    guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
                        throw DataLoadError.fileNotFound("\(fileName).json")
                    }
                    let data = try Data(contentsOf: url)
                    let opps = try decoder.decode([Opportunity].self, from: data)
                    allOpps.append(contentsOf: opps)
                }

                // Load companies
                guard let companiesURL = Bundle.main.url(forResource: "companies", withExtension: "json") else {
                    throw DataLoadError.fileNotFound("companies.json")
                }
                let companiesData = try Data(contentsOf: companiesURL)

                let loadedOpps = allOpps
                let loadedCompanies = try decoder.decode([Company].self, from: companiesData)

                // Pre-compute company matching
                let cache = Self.computeMatching(opportunities: loadedOpps, companies: loadedCompanies)

                DispatchQueue.main.async {
                    self.opportunities = loadedOpps
                    self.companies = loadedCompanies
                    self.matchingCache = cache
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load data: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    func refreshData() {
        loadData()
    }

    func getCompanies(forOpportunity opportunity: Opportunity) -> [Company] {
        let matchingIds = matchingCache[opportunity.id] ?? []
        return companies.filter { matchingIds.contains($0.id) }
    }

    func getAdvertisingCompanies() -> [Company] {
        companies.filter { $0.isAdvertising }
    }

    // MARK: - Company Matching Logic

    /// Keywords that map each company to the types of roles they recruit for
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

    /// Compute matching between opportunities and companies based on title keywords
    private static func computeMatching(opportunities: [Opportunity], companies: [Company]) -> [String: [String]] {
        var cache: [String: [String]] = [:]

        for opp in opportunities {
            let titleLower = opp.title.lowercased()
            var matchedIds: [String] = []

            for company in companies {
                guard company.isAdvertising else { continue }
                let keywords = companyKeywords[company.id] ?? []

                let matches = keywords.contains { keyword in
                    titleLower.contains(keyword)
                }

                if matches {
                    matchedIds.append(company.id)
                }
            }

            cache[opp.id] = matchedIds
        }

        return cache
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
