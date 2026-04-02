import Foundation

/// User's professional profile for matching against opportunities
class UserProfileService: ObservableObject {
    static let shared = UserProfileService()

    @Published var profile: UserProfile {
        didSet { save() }
    }

    private let storageKey = "govops_user_profile"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = saved
        } else {
            profile = UserProfile()
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func reset() {
        profile = UserProfile()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    /// Match opportunities to user profile
    func matchingOpportunities(from opportunities: [Opportunity]) -> [ScoredOpportunity] {
        guard !profile.sfiaSkillIds.isEmpty || !profile.freeTextSkills.isEmpty else {
            return []
        }

        return opportunities.compactMap { opp in
            let score = calculateMatchScore(for: opp)
            guard score > 0 else { return nil }
            return ScoredOpportunity(opportunity: opp, matchScore: score, matchReasons: matchReasons(for: opp))
        }.sorted { $0.matchScore > $1.matchScore }
    }

    private func calculateMatchScore(for opp: Opportunity) -> Double {
        let titleLower = opp.title.lowercased()
        var score = 0.0

        // SFIA skill matching
        for skillId in profile.sfiaSkillIds {
            if let skill = SkillsTaxonomyDB.skill(byId: skillId) {
                for keyword in skill.keywords {
                    if titleLower.contains(keyword.lowercased()) {
                        score += 20.0
                        break
                    }
                }
            }
        }

        // Free text skill matching
        for freeSkill in profile.freeTextSkills {
            if titleLower.contains(freeSkill.lowercased()) {
                score += 15.0
            }
        }

        // Location matching
        if let prefLocation = profile.preferredLocation, !prefLocation.isEmpty {
            if opp.location.lowercased().contains(prefLocation.lowercased()) {
                score += 10.0
            }
        }

        // Arrangement matching
        if let prefArrangement = profile.preferredArrangement, !prefArrangement.isEmpty {
            if opp.arrangement.lowercased().contains(prefArrangement.lowercased()) {
                score += 5.0
            }
        }

        return score
    }

    private func matchReasons(for opp: Opportunity) -> [String] {
        let titleLower = opp.title.lowercased()
        var reasons: [String] = []

        for skillId in profile.sfiaSkillIds {
            if let skill = SkillsTaxonomyDB.skill(byId: skillId) {
                for keyword in skill.keywords {
                    if titleLower.contains(keyword.lowercased()) {
                        reasons.append("Matches your \(skill.name) skill")
                        break
                    }
                }
            }
        }

        for freeSkill in profile.freeTextSkills {
            if titleLower.contains(freeSkill.lowercased()) {
                reasons.append("Matches '\(freeSkill)'")
            }
        }

        if let prefLocation = profile.preferredLocation, !prefLocation.isEmpty,
           opp.location.lowercased().contains(prefLocation.lowercased()) {
            reasons.append("Preferred location")
        }

        return reasons
    }
}

struct UserProfile: Codable {
    var sfiaSkillIds: [String] = []        // IDs from TaxonomySkill
    var freeTextSkills: [String] = []      // User-typed skills
    var clearanceLevel: String? = nil       // SecurityClearance rawValue
    var preferredLocation: String? = nil    // e.g. "ACT", "NSW"
    var preferredArrangement: String? = nil // e.g. "Hybrid", "Remote"
    var experienceYears: Int? = nil
    var linkedInURL: String? = nil
    var jobHistory: [String] = []          // Past job titles
}

struct ScoredOpportunity: Identifiable {
    var id: String { opportunity.id }
    let opportunity: Opportunity
    let matchScore: Double
    let matchReasons: [String]

    var matchPercentage: Int {
        min(100, Int(matchScore))
    }
}
