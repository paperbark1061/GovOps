import Foundation

struct Opportunity: Identifiable, Codable {
    let id: String
    let title: String
    let buyer: String
    let arrangement: String
    let location: String
    let closing: String
    let module: String
    let category: String
    let buyictURL: String?
    let sysId: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        buyer = try container.decode(String.self, forKey: .buyer)
        arrangement = try container.decodeIfPresent(String.self, forKey: .arrangement) ?? ""
        location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        closing = try container.decode(String.self, forKey: .closing)
        module = try container.decodeIfPresent(String.self, forKey: .module) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        buyictURL = try container.decodeIfPresent(String.self, forKey: .buyictURL)
        sysId = try container.decodeIfPresent(String.self, forKey: .sysId)
    }

    init(id: String, title: String, buyer: String, arrangement: String, location: String, closing: String, module: String, category: String, buyictURL: String? = nil, sysId: String? = nil) {
        self.id = id
        self.title = title
        self.buyer = buyer
        self.arrangement = arrangement
        self.location = location
        self.closing = closing
        self.module = module
        self.category = category
        self.buyictURL = buyictURL
        self.sysId = sysId
    }

    /// Table name derived from ID prefix for building BuyICT URLs
    private var tableName: String {
        if id.hasPrefix("LH-") { return "u_lh_procurement" }
        else if id.hasPrefix("PCS-") { return "u_pcs_procurement" }
        else if id.hasPrefix("RFI-") { return "u_rfi_procurement" }
        else { return "" }
    }

    /// The effective BuyICT URL - builds from sysId if available, falls back to buyictURL, then general listing
    var effectiveBuyictURL: String {
        if let sysId = sysId, !sysId.isEmpty, !tableName.isEmpty {
            return "https://www.buyict.gov.au/public?id=opportunity_details&table=\(tableName)&sys_id=\(sysId)&entry=opp_page"
        }
        return buyictURL ?? "https://www.buyict.gov.au/sp?id=procurement_702702702&topic_id=292278ac1bf62a50f421db96b04bcbd5"
    }

    enum CodingKeys: String, CodingKey {
        case id, title, buyer, arrangement, location, closing, module, category
        case buyictURL, sysId
    }

    var skills: [String] {
        extractSkillsFromTitle(title)
    }

    var moduleColor: String {
        switch module.lowercased() {
        case let m where m.contains("labour"):
            return "blue"
        case let m where m.contains("professional"):
            return "green"
        case let m where m.contains("rfi"):
            return "orange"
        default:
            return "gray"
        }
    }

    private func extractSkillsFromTitle(_ title: String) -> [String] {
        let titleLower = title.lowercased()
        var extractedSkills: [String] = []

        let skillPatterns: [(String, String)] = [
            (".NET", ".NET|dot net|dotnet"),
            ("SAP", "sap"),
            ("Cyber", "cyber|security|infosec"),
            ("Cloud", "cloud|aws|azure|gcp|openstack"),
            ("Testing", "testing|qa|qc|automation|test"),
            ("Java", "java(?!script)"),
            ("Oracle", "oracle|plsql|pl/sql"),
            ("Data", "data(?!base)|analytics|bi|business intelligence|dwh|data warehouse"),
            ("UX", "ux|user experience|ui design|design|frontend"),
            ("Infrastructure", "infrastructure|sysadmin|sys admin|windows|linux|unix"),
            ("DevOps", "devops|ci/cd|deployment|containerization|docker|kubernetes"),
            ("Project Management", "pmp|project manager|project management|scrum|agile|prince2"),
        ]

        for (skillName, pattern) in skillPatterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            if let regex = regex, regex.firstMatch(in: titleLower, range: NSRange(titleLower.startIndex..., in: titleLower)) != nil {
                if !extractedSkills.contains(skillName) {
                    extractedSkills.append(skillName)
                }
            }
        }

        return extractedSkills.sorted()
    }
}
