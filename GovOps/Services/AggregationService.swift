import Foundation
import Combine

/// Service that aggregates opportunities from multiple government tender sources.
/// Uses APIs where available (AusTender OCDS, NSW eTendering) and web scraping for the rest.
class AggregationService: ObservableObject {
    static let shared = AggregationService()

    @Published var unifiedOpportunities: [UnifiedOpportunity] = []
    @Published var isAggregating: Bool = false
    @Published var sourceStatuses: [String: SourceFetchStatus] = [:]
    @Published var lastAggregation: Date? = nil

    private init() {
        // Initialise all source statuses
        for source in TenderSourceDB.sources {
            sourceStatuses[source.id] = SourceFetchStatus(
                sourceId: source.id,
                status: source.isActive ? .idle : .disabled,
                lastFetch: nil,
                count: 0,
                error: nil
            )
        }
    }

    // MARK: - Public API

    /// Trigger a full aggregation across all active sources
    func aggregateAll() async {
        await MainActor.run { isAggregating = true }

        var allOpportunities: [UnifiedOpportunity] = []

        for source in TenderSourceDB.activeSources() {
            await updateStatus(source.id, status: .fetching)

            do {
                let opportunities = try await fetchFromSource(source)
                allOpportunities.append(contentsOf: opportunities)
                await updateStatus(source.id, status: .success, count: opportunities.count)
            } catch {
                await updateStatus(source.id, status: .error, error: error.localizedDescription)
            }
        }

        // Deduplicate by title + buyer similarity
        let deduped = deduplicateOpportunities(allOpportunities)

        await MainActor.run {
            self.unifiedOpportunities = deduped
            self.isAggregating = false
            self.lastAggregation = Date()
        }
    }

    /// Fetch from a single source
    func fetchFromSource(_ source: TenderSource) async throws -> [UnifiedOpportunity] {
        switch source.id {
        case "buyict":
            return try await fetchBuyICT()
        case "austender":
            return try await fetchAusTender()
        case "nsw-etender":
            return try await fetchNSWeTendering()
        default:
            return try await fetchViaGenericScraper(source)
        }
    }

    // MARK: - Source-Specific Fetchers

    /// Fetch from AusTender OCDS API
    private func fetchAusTender() async throws -> [UnifiedOpportunity] {
        // AusTender OCDS API endpoint
        // GET https://api.tenders.gov.au/ocds/findByDates/publishedDate/{startDate}/{endDate}
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"

        let startStr = dateFormatter.string(from: startDate)
        let endStr = dateFormatter.string(from: endDate)

        let urlString = "https://api.tenders.gov.au/ocds/findByDates/publishedDate/\(startStr)/\(endStr)"

        guard let url = URL(string: urlString) else {
            throw AggregationError.invalidURL(urlString)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AggregationError.httpError(urlString)
        }

        // Parse OCDS release packages
        let releases = try parseOCDSReleases(data)
        return releases.map { release in
            UnifiedOpportunity(
                id: "austender-\(release.id)",
                sourceId: release.id,
                source: "austender",
                title: release.title,
                description: release.description,
                buyer: release.buyer,
                category: release.category,
                location: release.location ?? "National",
                closingDate: release.closingDate ?? "Not specified",
                publishedDate: release.publishedDate,
                value: release.value,
                arrangement: nil,
                module: nil,
                status: .open,
                url: "https://www.tenders.gov.au/Search/SearchResult?SearchFrom=AdvancedSearch&KeywordTypeSearch=AllWord&ATMIDSearch=\(release.id)",
                documentURLs: [],
                extractedSkills: SkillsTaxonomyDB.extractSkills(from: release.title + " " + (release.description ?? "")).map { $0.matchedKeyword },
                clearanceRequired: SkillsTaxonomyDB.extractClearance(from: release.title + " " + (release.description ?? ""))?.rawValue,
                lastUpdated: Date()
            )
        }
    }

    /// Fetch from NSW eTendering API
    private func fetchNSWeTendering() async throws -> [UnifiedOpportunity] {
        // NSW eTendering API via api.nsw.gov.au
        // Requires API key registration at api.nsw.gov.au
        let urlString = "https://api.nsw.gov.au/tender/v1/tenders?status=open&category=ict"

        guard let url = URL(string: urlString) else {
            throw AggregationError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        // API key would go here: request.addValue(apiKey, forHTTPHeaderField: "x-api-key")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AggregationError.httpError(urlString)
        }

        // Parse NSW-specific JSON format
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw AggregationError.parseError("NSW eTendering")
        }

        return json.compactMap { item -> UnifiedOpportunity? in
            guard let id = item["RFTTENDERID"] as? String,
                  let title = item["RFTTITLE"] as? String else { return nil }

            let agency = item["AGENCYNAME"] as? String ?? "NSW Government"
            let closeDate = item["RFTCLOSINGDATE"] as? String ?? "Not specified"

            return UnifiedOpportunity(
                id: "nsw-\(id)",
                sourceId: id,
                source: "nsw-etender",
                title: title,
                description: item["RFTDESCRIPTION"] as? String,
                buyer: agency,
                category: item["RFTCATEGORY"] as? String,
                location: "NSW",
                closingDate: closeDate,
                publishedDate: item["RFTPUBLISHEDDATE"] as? String,
                value: nil,
                arrangement: nil,
                module: nil,
                status: .open,
                url: "https://tenders.nsw.gov.au/?event=public.rft.show&RFTUUID=\(id)",
                documentURLs: [],
                extractedSkills: SkillsTaxonomyDB.extractSkills(from: title).map { $0.matchedKeyword },
                clearanceRequired: nil,
                lastUpdated: Date()
            )
        }
    }

    /// Fetch from BuyICT (convert existing local data)
    private func fetchBuyICT() async throws -> [UnifiedOpportunity] {
        // Convert locally loaded BuyICT opportunities to unified format
        let opps = await MainActor.run { DataService.shared.opportunities }
        return opps.map { opp in
            UnifiedOpportunity(
                id: "buyict-\(opp.id)",
                sourceId: opp.id,
                source: "buyict",
                title: opp.title,
                description: nil,
                buyer: opp.buyer,
                category: opp.category,
                location: opp.location,
                closingDate: opp.closing,
                publishedDate: nil,
                value: nil,
                arrangement: opp.arrangement,
                module: opp.module,
                status: .open,
                url: opp.effectiveBuyictURL,
                documentURLs: [],
                extractedSkills: opp.skills,
                clearanceRequired: nil,
                lastUpdated: Date()
            )
        }
    }

    /// Generic scraper placeholder for state sites
    private func fetchViaGenericScraper(_ source: TenderSource) async throws -> [UnifiedOpportunity] {
        // Placeholder for future scraper implementations
        // Each state site will need a custom HTML parser
        throw AggregationError.scraperNotImplemented(source.name)
    }

    // MARK: - OCDS Parser

    private struct OCDSRelease {
        let id: String
        let title: String
        let description: String?
        let buyer: String
        let category: String?
        let location: String?
        let closingDate: String?
        let publishedDate: String?
        let value: String?
    }

    private func parseOCDSReleases(_ data: Data) throws -> [OCDSRelease] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let releases = json["releases"] as? [[String: Any]] else {
            throw AggregationError.parseError("AusTender OCDS")
        }

        return releases.compactMap { release -> OCDSRelease? in
            guard let id = release["ocid"] as? String else { return nil }

            let tender = release["tender"] as? [String: Any]
            let title = tender?["title"] as? String ?? "Untitled"
            let description = tender?["description"] as? String

            let parties = release["parties"] as? [[String: Any]] ?? []
            let buyerParty = parties.first { ($0["roles"] as? [String])?.contains("buyer") == true }
            let buyer = buyerParty?["name"] as? String ?? "Commonwealth of Australia"

            let tenderPeriod = tender?["tenderPeriod"] as? [String: Any]
            let closingDate = tenderPeriod?["endDate"] as? String

            let items = tender?["items"] as? [[String: Any]] ?? []
            let classification = items.first?["classification"] as? [String: Any]
            let category = classification?["description"] as? String

            let publishedDate = release["date"] as? String

            let valueObj = tender?["value"] as? [String: Any]
            var value: String? = nil
            if let amount = valueObj?["amount"] as? Double {
                value = String(format: "$%.0f", amount)
            }

            return OCDSRelease(
                id: id, title: title, description: description,
                buyer: buyer, category: category, location: nil,
                closingDate: closingDate, publishedDate: publishedDate,
                value: value
            )
        }
    }

    // MARK: - Deduplication

    private func deduplicateOpportunities(_ opportunities: [UnifiedOpportunity]) -> [UnifiedOpportunity] {
        var seen: Set<String> = []
        var result: [UnifiedOpportunity] = []

        for opp in opportunities {
            let key = "\(opp.title.lowercased().prefix(50))|\(opp.buyer.lowercased())"
            if !seen.contains(key) {
                seen.insert(key)
                result.append(opp)
            }
        }

        return result.sorted { $0.closingDate > $1.closingDate }
    }

    // MARK: - Status Management

    @MainActor
    private func updateStatus(_ sourceId: String, status: FetchStatus, count: Int = 0, error: String? = nil) {
        sourceStatuses[sourceId] = SourceFetchStatus(
            sourceId: sourceId,
            status: status,
            lastFetch: status == .success ? Date() : sourceStatuses[sourceId]?.lastFetch,
            count: count,
            error: error
        )
    }
}

// MARK: - Supporting Types

struct SourceFetchStatus {
    let sourceId: String
    let status: FetchStatus
    let lastFetch: Date?
    let count: Int
    let error: String?
}

enum FetchStatus {
    case idle, fetching, success, error, disabled
}

enum AggregationError: LocalizedError {
    case invalidURL(String)
    case httpError(String)
    case parseError(String)
    case scraperNotImplemented(String)
    case apiKeyMissing(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url): return "Invalid URL: \(url)"
        case .httpError(let url): return "HTTP error fetching \(url)"
        case .parseError(let source): return "Failed to parse data from \(source)"
        case .scraperNotImplemented(let source): return "Scraper not yet implemented for \(source)"
        case .apiKeyMissing(let source): return "API key required for \(source)"
        }
    }
}
