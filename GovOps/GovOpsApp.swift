import SwiftUI

@main
struct GovICTJobsApp: App {
    @StateObject private var dataService = DataService.shared
    @StateObject private var authService = AuthService.shared
    @StateObject private var profileService = UserProfileService.shared

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(dataService)
                .environmentObject(authService)
                .environmentObject(profileService)
        }
    }
}
