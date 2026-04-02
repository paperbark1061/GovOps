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

    enum CodingKeys: String, CodingKey {
        case id, name, isAdvertising, advertisingRoles, platforms, websiteURL, jobsURL, buyictURL
    }
}
