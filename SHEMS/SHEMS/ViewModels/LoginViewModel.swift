//
//  LoginViewModel.swift
//  SHEMS
//

import SwiftUI
import FirebaseAuth


class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    func signInUser(appState: AppState) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }

        isLoading = true
        errorMessage = nil

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let user = authResult?.user else {
                    self.errorMessage = "User not found."
                    return
                }

                if user.isEmailVerified {
                    // Email is verified, update the app state to show the LandingView
                    appState.isLoggedIn = true
                } else {
                    // Email is not verified, show error message
                    self.errorMessage = "Please verify your email before logging in."
                }
            }
        }
    }

    func resetPassword() {
        guard !email.isEmpty else {
            errorMessage = "Enter your email to reset the password."
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.errorMessage = "✅ Password reset email sent!"
                }
            }
        }
    }
}
