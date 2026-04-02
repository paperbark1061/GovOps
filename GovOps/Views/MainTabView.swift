import SwiftUI

/// Main tab navigation after authentication.
/// Provides access to Opportunities, Skills, Companies, and Profile.
struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var dataService: DataService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            JobListView()
                .tabItem {
                    Label("Opportunities", systemImage: "briefcase.fill")
                }
                .tag(0)

            SkillsExplorerView()
                .tabItem {
                    Label("Skills", systemImage: "graduationcap.fill")
                }
                .tag(1)

            CompanyListView()
                .tabItem {
                    Label("Companies", systemImage: "building.2.fill")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationStack {
            List {
                // User info section
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 56, height: 56)

                            Text(authService.currentUser?.initials ?? "??")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.currentUser?.name ?? "User")
                                .font(.headline)

                            Text(authService.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .font(.caption2)
                                Text(authService.currentUser?.plan.displayName ?? "Demo")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Session info
                if let expiry = authService.sessionExpiresAt {
                    Section("Session") {
                        HStack {
                            Label("Expires", systemImage: "clock")
                                .font(.subheadline)
                            Spacer()
                            Text(expiry, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Label("Plan", systemImage: "creditcard")
                                .font(.subheadline)
                            Spacer()
                            Text(authService.currentUser?.plan.displayName ?? "Demo")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Data sources
                Section("Data Sources") {
                    SourceRow(name: "BuyICT", status: .active, count: "127 opportunities")
                    SourceRow(name: "AusTender", status: .planned, count: "Coming soon")
                    SourceRow(name: "NSW eTendering", status: .planned, count: "Coming soon")
                    SourceRow(name: "State Portals", status: .planned, count: "8 portals planned")
                }

                // Subscription
                Section("Subscription") {
                    ForEach(SubscriptionPlan.allCases, id: \.rawValue) { plan in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(plan.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(plan.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if plan == authService.currentUser?.plan {
                                Text("Current")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                // Sign out
                Section {
                    Button(action: { authService.logout() }) {
                        HStack {
                            Spacer()
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SourceRow: View {
    let name: String
    let status: SourceStatus
    let count: String

    enum SourceStatus {
        case active, planned, error

        var color: Color {
            switch self {
            case .active: return .green
            case .planned: return .orange
            case .error: return .red
            }
        }

        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .planned: return "clock.fill"
            case .error: return "exclamationmark.circle.fill"
            }
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                Text(count)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: status.icon)
                .foregroundColor(status.color)
                .font(.body)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService.shared)
        .environmentObject(DataService.shared)
}
