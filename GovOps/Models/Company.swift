import Foundation

struct Company: Identifiable, Codable {
    let id: String
    let name: String
    let isAdvertising: Bool
    let advertisingRoles: [String]
    let platforms: [String]
    let websiteURL: String?
    let jobsURL: String?
    let buyictURL: String?
    // New enriched fields
    let description: String?
    let headquarters: String?
    let specialties: [String]?
    let panels: [PanelMembership]?
    let abn: String?

    enum CodingKeys: String, CodingKey {
        case id, name, isAdvertising, advertisingRoles, platforms, websiteURL, jobsURL, buyictURL
        case description, headquarters, specialties, panels, abn
    }

    // Memberwise init for programmatic creation
    init(id: String, name: String, isAdvertising: Bool = false, advertisingRoles: [String] = [], platforms: [String] = [],
         websiteURL: String? = nil, jobsURL: String? = nil, buyictURL: String? = nil,
         description: String? = nil, headquarters: String? = nil, specialties: [String]? = nil,
         panels: [PanelMembership]? = nil, abn: String? = nil) {
        self.id = id
        self.name = name
        self.isAdvertising = isAdvertising
        self.advertisingRoles = advertisingRoles
        self.platforms = platforms
        self.websiteURL = websiteURL
        self.jobsURL = jobsURL
        self.buyictURL = buyictURL
        self.description = description
        self.headquarters = headquarters
        self.specialties = specialties
        self.panels = panels
        self.abn = abn
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"
        isAdvertising = try container.decodeIfPresent(Bool.self, forKey: .isAdvertising) ?? false
        advertisingRoles = try container.decodeIfPresent([String].self, forKey: .advertisingRoles) ?? []
        platforms = try container.decodeIfPresent([String].self, forKey: .platforms) ?? []
        websiteURL = try container.decodeIfPresent(String.self, forKey: .websiteURL)
        jobsURL = try container.decodeIfPresent(String.self, forKey: .jobsURL)
        buyictURL = try container.decodeIfPresent(String.self, forKey: .buyictURL)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        headquarters = try container.decodeIfPresent(String.self, forKey: .headquarters)
        specialties = try container.decodeIfPresent([String].self, forKey: .specialties)
        panels = try container.decodeIfPresent([PanelMembership].self, forKey: .panels)
        abn = try container.decodeIfPresent(String.self, forKey: .abn)
    }
}

struct PanelMembership: Codable, Identifiable {
    var id: String { "\(panelName)-\(category)" }
    let panelName: String        // e.g. "BuyICT", "NSW ICT Services Scheme"
    let category: String         // e.g. "Labour Hire", "Professional Services"
    let jurisdiction: String     // e.g. "Federal", "NSW", "VIC"
    let isActive: Bool
}
