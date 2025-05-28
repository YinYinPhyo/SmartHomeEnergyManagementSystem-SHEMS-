import SwiftUI
import FirebaseAuth

class AppState: ObservableObject {
    @Published var isFirstLaunch: Bool
    @Published var isLoggedIn: Bool

    init() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        isFirstLaunch = !hasLaunchedBefore
        isLoggedIn = Auth.auth().currentUser != nil

        if !hasLaunchedBefore {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        
        // Listen for changes in authentication state
        Auth.auth().addStateDidChangeListener { _, user in
            DispatchQueue.main.async {
                self.isLoggedIn = user != nil && (user?.isEmailVerified ?? false)
            }
        }
    }
}
