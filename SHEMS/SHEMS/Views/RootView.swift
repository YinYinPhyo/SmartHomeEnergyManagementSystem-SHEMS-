import SwiftUI
import FirebaseAuth

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showSplash = false
                        }
                    }
            } else {
                if appState.isLoggedIn {
                    LandingView()
                } else {
                    LoginView()
                }
            }
        }
        .transition(.opacity)
        .onAppear {
            // Listen for authentication state changes
            Auth.auth().addStateDidChangeListener { _, user in
                DispatchQueue.main.async {
                    // Check if the user is logged in and if the email is verified
                    appState.isLoggedIn = user != nil && (user?.isEmailVerified ?? false)
                }
            }
        }
    }
}
