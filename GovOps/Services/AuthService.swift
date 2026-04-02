import Foundation
import Combine

/// Authentication service managing user sessions.
/// Currently operates in demo mode — all logins succeed.
/// Future: integrate with backend for subscription/pay-per-login model.
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isAuthenticated: Bool = false
    @Published var currentUser: GovOpsUser? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    /// Session expiry support for future pay-per-login model
    @Published var sessionExpiresAt: Date? = nil

    private init() {
        // Check for persisted session
        if let savedEmail = UserDefaults.standard.string(forKey: "govops_user_email") {
            let name = UserDefaults.standard.string(forKey: "govops_user_name") ?? ""
            let plan = UserDefaults.standard.string(forKey: "govops_user_plan") ?? "demo"
            currentUser = GovOpsUser(
                email: savedEmail,
                name: name,
                plan: SubscriptionPlan(rawValue: plan) ?? .demo
            )
            isAuthenticated = true
        }
    }

    /// Login with email/password. Demo mode: always succeeds.
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Demo mode — accept any credentials
            let user = GovOpsUser(
                email: email,
                name: email.components(separatedBy: "@").first?.capitalized ?? "User",
                plan: .demo
            )
            self.currentUser = user
            self.isAuthenticated = true
            self.isLoading = false

            // Demo session: 30 days
            self.sessionExpiresAt = Calendar.current.date(byAdding: .day, value: 30, to: Date())

            // Persist session
            UserDefaults.standard.set(email, forKey: "govops_user_email")
            UserDefaults.standard.set(user.name, forKey: "govops_user_name")
            UserDefaults.standard.set(user.plan.rawValue, forKey: "govops_user_plan")
        }
    }

    /// Quick demo access without credentials
    func loginAsDemo() {
        let user = GovOpsUser(email: "demo@govops.au", name: "Demo User", plan: .demo)
        currentUser = user
        isAuthenticated = true
        sessionExpiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date())

        UserDefaults.standard.set(user.email, forKey: "govops_user_email")
        UserDefaults.standard.set(user.name, forKey: "govops_user_name")
        UserDefaults.standard.set(user.plan.rawValue, forKey: "govops_user_plan")
    }

    func logout() {
        currentUser = nil
        isAuthenticated = false
        sessionExpiresAt = nil
        errorMessage = nil

        UserDefaults.standard.removeObject(forKey: "govops_user_email")
        UserDefaults.standard.removeObject(forKey: "govops_user_name")
        UserDefaults.standard.removeObject(forKey: "govops_user_plan")
    }

    /// Check if session is still valid
    var isSessionValid: Bool {
        guard isAuthenticated else { return false }
        if let expiry = sessionExpiresAt {
            return Date() < expiry
        }
        return true // No expiry set = valid
    }
}

// MARK: - Models

struct GovOpsUser: Codable, Identifiable {
    var id: String { email }
    let email: String
    let name: String
    let plan: SubscriptionPlan

    var initials: String {
        let parts = name.components(separatedBy: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

enum SubscriptionPlan: String, Codable, CaseIterable {
    case demo = "demo"
    case payPerLogin = "pay_per_login"
    case monthly = "monthly"
    case annual = "annual"

    var displayName: String {
        switch self {
        case .demo: return "Demo"
        case .payPerLogin: return "Pay Per Login"
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }

    var description: String {
        switch self {
        case .demo: return "Full access for testing and evaluation"
        case .payPerLogin: return "Pay each time you log in, stay active for 7 days"
        case .monthly: return "Unlimited access, billed monthly"
        case .annual: return "Unlimited access, billed annually (save 20%)"
        }
    }
}
