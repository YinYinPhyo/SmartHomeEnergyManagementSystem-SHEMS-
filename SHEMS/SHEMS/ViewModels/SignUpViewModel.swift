import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

@MainActor
class SignUpViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isPasswordVisible = false
    @Published var isConfirmPasswordVisible = false
    @Published var showVerificationAlert = false
    @Published var navigateToSignIn = false // Control navigation to Sign In page
    
    private let db = Firestore.firestore()
    private var locationManager = CLLocationManager()
    private var registeredUser: User? // Store registered user temporarily
    
    @Published var userLatitude: Double?
    @Published var userLongitude: Double?
    @Published var rate: Double = 0.41


    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // Request permission
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }

    func registerUser() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "All fields are required."
            return
        }

        guard isValidEmail(email) else {
            errorMessage = "Invalid email format."
            return
        }

        guard isValidPassword(password) else {
            errorMessage = "Password must be at least 6 characters."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true
        errorMessage = nil

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let user = authResult?.user else { return }
                self.registeredUser = user // Store the user for later use
                
                user.sendEmailVerification { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = error.localizedDescription
                        } else {
                            self.showVerificationAlert = true
                            self.locationManager.startUpdatingLocation() // Get user location before saving
                        }
                    }
                }
            }
        }
    }

    
    func saveUserData() {
        guard let user = registeredUser,
              let latitude = userLatitude,
              let longitude = userLongitude else {
            print("❗️User or location data is missing")
            self.errorMessage = "Missing user or location data"
            return
        }

        let userModel = UserModel(
            uid: user.uid,
            name: self.name,
            email: self.email,
            latitude: latitude,
            longitude: longitude,
            rate: rate
        )

        do {
            try db.collection("users").document(user.uid).setData(from: userModel) { error in
                if let error = error {
                    self.errorMessage = "🔥 Failed to save user data: \(error.localizedDescription)"
                    print(self.errorMessage ?? "")
                } else {
                    print("✅ User data saved successfully!")
                }
            }
        } catch {
            self.errorMessage = "🔥 Failed to encode user data: \(error.localizedDescription)"
            print(self.errorMessage ?? "")
        }
    }


    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLatitude = location.coordinate.latitude
            userLongitude = location.coordinate.longitude
            locationManager.stopUpdatingLocation() // Stop updates after getting the location

            saveUserData() // Now we have the location, save user data
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
}
