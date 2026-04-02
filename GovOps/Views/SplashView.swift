import SwiftUI

struct SplashView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showLogin = false
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0

    var body: some View {
        if authService.isAuthenticated {
            MainTabView()
                .environmentObject(authService)
                .environmentObject(DataService.shared)
        } else {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.10, blue: 0.25),
                        Color(red: 0.08, green: 0.18, blue: 0.38),
                        Color(red: 0.05, green: 0.10, blue: 0.25)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Logo and branding
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.3), Color.teal.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 52))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, Color(red: 0.6, green: 0.85, blue: 1.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                        Text("GovOps")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .opacity(logoOpacity)

                        Text("Australian Government\nICT Opportunities")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .opacity(taglineOpacity)
                    }

                    Spacer()

                    // Feature highlights
                    VStack(spacing: 12) {
                        FeatureRow(icon: "magnifyingglass", text: "Search tenders across all government portals")
                        FeatureRow(icon: "building.2", text: "Find companies actively recruiting")
                        FeatureRow(icon: "chart.bar", text: "Track skills demand and market trends")
                        FeatureRow(icon: "graduationcap", text: "Discover training pathways for required skills")
                    }
                    .padding(.horizontal, 32)
                    .opacity(taglineOpacity)

                    Spacer()

                    // Action buttons
                    VStack(spacing: 14) {
                        Button(action: { showLogin = true }) {
                            HStack {
                                Image(systemName: "person.fill")
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white)
                            .foregroundColor(Color(red: 0.05, green: 0.10, blue: 0.25))
                            .cornerRadius(14)
                        }

                        Button(action: { authService.loginAsDemo() }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Try Demo")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 16)
                    .opacity(buttonsOpacity)

                    Text("Aggregating opportunities from AusTender, BuyICT, and all state portals")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 24)
                        .opacity(buttonsOpacity)
                }
            }
            .sheet(isPresented: $showLogin) {
                LoginView()
                    .environmentObject(authService)
            }
            .onChange(of: authService.isAuthenticated) { _, isAuth in
                if isAuth {
                    showLogin = false
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                    taglineOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
                    buttonsOpacity = 1.0
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(Color(red: 0.6, green: 0.85, blue: 1.0))
                .frame(width: 28)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))

            Spacer()
        }
    }
}

#Preview {
    SplashView()
}
