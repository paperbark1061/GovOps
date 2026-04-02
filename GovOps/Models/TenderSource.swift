import Foundation

// MARK: - Tender Source Model

/// Represents a government procurement/tender platform
struct TenderSource: Identifiable, Codable {
    let id: String
    let name: String
    let url: String
    let coverage: SourceCoverage
    let integrationType: IntegrationType
    let isActive: Bool
    let ictRelevance: ICTRelevance
    let description: String

    /// Whether this source has a usable API
    var hasAPI: Bool {
        integrationType == .api || integrationType == .apiAndScrape
    }
}

enum SourceCoverage: String, Codable, CaseIterable {
    case federal = "Federal"
    case nsw = "NSW"
    case vic = "VIC"
    case qld = "QLD"
    case wa = "WA"
    case sa = "SA"
    case tas = "TAS"
    case nt = "NT"
    case act = "ACT"
    case national = "National"
    case local = "Local Government"

    var displayName: String { rawValue }
}

enum IntegrationType: String, Codable {
    case api = "API"
    case scrape = "Scrape"
    case apiAndScrape = "API + Scrape"
    case manual = "Manual"
}

enum ICTRelevance: String, Codable {
    case veryHigh = "Very High"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

// MARK: - Unified Opportunity Model (Multi-Source)

/// An opportunity from any government tender source, normalised to a common schema
struct UnifiedOpportunity: Identifiable, Codable {
    let id: String                    // Unique across all sources
    let sourceId: String              // Original ID from the source
    let source: String                // TenderSource.id
    let title: String
    let description: String?
    let buyer: String
    let category: String?
    let location: String
    let closingDate: String
    let publishedDate: String?
    let value: String?                // Contract value if disclosed
    let arrangement: String?
    let module: String?               // BuyICT-specific
    let status: OpportunityStatus
    let url: String                   // Direct link to the opportunity
    let documentURLs: [String]        // Attached documents
    let extractedSkills: [String]     // Skills extracted from title/description
    let clearanceRequired: String?    // Security clearance if mentioned
    let lastUpdated: Date

    var sourceName: String {
        TenderSourceDB.source(byId: source)?.name ?? source
    }
}

enum OpportunityStatus: String, Codable {
    case open = "Open"
    case closed = "Closed"
    case withdrawn = "Withdrawn"
    case awarded = "Awarded"
    case unknown = "Unknown"
}

// MARK: - Source Database

struct TenderSourceDB {

    static let sources: [TenderSource] = [
        // Federal
        TenderSource(id: "austender", name: "AusTender", url: "https://www.tenders.gov.au",
                    coverage: .federal, integrationType: .api, isActive: true,
                    ictRelevance: .high,
                    description: "Primary federal procurement portal. OCDS-compliant API available."),

        TenderSource(id: "buyict", name: "BuyICT", url: "https://www.buyict.gov.au",
                    coverage: .federal, integrationType: .scrape, isActive: true,
                    ictRelevance: .veryHigh,
                    description: "ICT-specific marketplace. Labour Hire, Professional Services, RFI."),

        // State & Territory
        TenderSource(id: "nsw-etender", name: "NSW eTendering", url: "https://tenders.nsw.gov.au",
                    coverage: .nsw, integrationType: .api, isActive: false,
                    ictRelevance: .high,
                    description: "NSW Government eTendering. API via api.nsw.gov.au."),

        TenderSource(id: "nsw-buy", name: "Buy.NSW", url: "https://buy.nsw.gov.au",
                    coverage: .nsw, integrationType: .scrape, isActive: false,
                    ictRelevance: .veryHigh,
                    description: "NSW procurement including ICT Services Scheme."),

        TenderSource(id: "vic-tenders", name: "VIC Tenders", url: "https://tenders.vic.gov.au",
                    coverage: .vic, integrationType: .scrape, isActive: false,
                    ictRelevance: .high,
                    description: "Victorian Government Purchasing Board tenders."),

        TenderSource(id: "qld-qtenders", name: "QLD QTenders", url: "https://qtenders.hpw.qld.gov.au",
                    coverage: .qld, integrationType: .scrape, isActive: false,
                    ictRelevance: .high,
                    description: "Queensland Government Marketplace. Transitioning to VendorPanel."),

        TenderSource(id: "wa-tenders", name: "WA Tenders", url: "https://www.tenders.wa.gov.au",
                    coverage: .wa, integrationType: .scrape, isActive: false,
                    ictRelevance: .high,
                    description: "Western Australian Government tenders including ICT CUAs."),

        TenderSource(id: "sa-tenders", name: "SA Tenders", url: "https://www.tenders.sa.gov.au",
                    coverage: .sa, integrationType: .scrape, isActive: false,
                    ictRelevance: .high,
                    description: "South Australian Government tenders and contracts."),

        TenderSource(id: "tas-tenders", name: "TAS Tenders", url: "https://www.tenders.tas.gov.au",
                    coverage: .tas, integrationType: .scrape, isActive: false,
                    ictRelevance: .medium,
                    description: "Tasmanian Government tenders. Technology Services List."),

        TenderSource(id: "nt-tenders", name: "NT TendersOnline", url: "https://tendersonline.nt.gov.au",
                    coverage: .nt, integrationType: .scrape, isActive: false,
                    ictRelevance: .medium,
                    description: "Northern Territory Government procurement portal."),

        TenderSource(id: "act-tenders", name: "ACT Tenders", url: "https://www.tenders.act.gov.au",
                    coverage: .act, integrationType: .scrape, isActive: false,
                    ictRelevance: .high,
                    description: "ACT Government tenders. Significant ICT spend."),

        // Local Government
        TenderSource(id: "lgp", name: "LGP", url: "https://www.lgp.org.au",
                    coverage: .local, integrationType: .scrape, isActive: false,
                    ictRelevance: .medium,
                    description: "Local Government Procurement portal for councils."),

        TenderSource(id: "vendorpanel", name: "VendorPanel", url: "https://www.vendorpanel.com",
                    coverage: .national, integrationType: .scrape, isActive: false,
                    ictRelevance: .medium,
                    description: "Used by local governments and some state agencies.")
    ]

    static func source(byId id: String) -> TenderSource? {
        sources.first { $0.id == id }
    }

    static func activeSources() -> [TenderSource] {
        sources.filter { $0.isActive }
    }

    static func sources(forCoverage coverage: SourceCoverage) -> [TenderSource] {
        sources.filter { $0.coverage == coverage }
    }
}
