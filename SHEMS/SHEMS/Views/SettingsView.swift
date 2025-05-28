//import SwiftUI
//import FirebaseAuth
//import FirebaseFirestore
//
//enum AppTheme: String, CaseIterable, Identifiable {
//    case system, light, dark
//    
//    var id: String { self.rawValue }
//    
//    var displayName: String {
//        switch self {
//        case .system: return "System Default"
//        case .light: return "Light"
//        case .dark: return "Dark"
//        }
//    }
//}
//
//struct SettingsView: View {
//    @State private var customRate: String = ""
//    @State private var useDefaultRate = true
//    @AppStorage("appTheme") private var selectedTheme: AppTheme = .system
//    
//    private let db = Firestore.firestore()
//
//    var body: some View {
//        Form {
//            // Energy Rate Section
//            Section(header: Text("Energy Rate Settings")) {
//                Toggle("Use Default Rate ($0.41/kWh)", isOn: $useDefaultRate)
//                
//                if !useDefaultRate {
//                    TextField("Enter your custom rate (e.g., 0.20)", text: $customRate)
//                        .keyboardType(.decimalPad)
//                }
//                
//                Button("Save Rate") {
//                    let rate = useDefaultRate ? 0.41 : (Double(customRate) ?? 0.41)
//                    saveRateToFirebase(rate: rate)
//                }
//            }
//            
//            // Appearance Section
//            Section(header: Text("App Appearance")) {
//                Picker("Theme", selection: $selectedTheme) {
//                    ForEach(AppTheme.allCases) { theme in
//                        Text(theme.displayName).tag(theme)
//                    }
//                }
//            }
//        }
//        .navigationTitle("Settings")
//    }
//    
//    func saveRateToFirebase(rate: Double) {
//        guard let currentUser = Auth.auth().currentUser else {
//            print("❗️User not authenticated.")
//            return
//        }
//        
//        // Assuming you want to save the rate under the user's document in Firestore
//        db.collection("users").document(currentUser.uid).updateData([
//            "rate": rate
//        ]) { error in
//            if let error = error {
//                print("❗️Failed to save rate: \(error.localizedDescription)")
//            } else {
//                print("✅ Rate saved successfully to Firestore: \(rate)")
//            }
//        }
//    }
//}

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

struct SettingsView: View {
    @State private var customRate: String = ""
    @State private var useDefaultRate = true
    @AppStorage("appTheme") private var selectedTheme: AppTheme = .system
    
    // Notification Toggles
    @AppStorage("notificationsEnabled_appliance") private var enableApplianceNotifications = true
    @AppStorage("notificationsEnabled_ai") private var enableAISuggestions = true
    @AppStorage("notificationsEnabled_predictions") private var enablePredictionNotifications = true

    private let db = Firestore.firestore()

    var body: some View {
        Form {
            // Energy Rate Section
            Section(header: Text("Energy Rate Settings")) {
                Toggle("Use Default Rate ($0.41/kWh)", isOn: $useDefaultRate)
                
                if !useDefaultRate {
                    TextField("Enter your custom rate (e.g., 0.20)", text: $customRate)
                        .keyboardType(.decimalPad)
                }
                
                Button("Save Rate") {
                    let rate = useDefaultRate ? 0.41 : (Double(customRate) ?? 0.41)
                    saveRateToFirebase(rate: rate)
                }
            }

            // Appearance Section
            Section(header: Text("App Appearance")) {
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            }

            // Notification Preferences
            Section(header: Text("Notifications")) {
                Toggle("Appliance ON/OFF Alerts", isOn: $enableApplianceNotifications)
                Toggle("AI Suggestions", isOn: $enableAISuggestions)
                Toggle("Energy Usage Prediction Updates", isOn: $enablePredictionNotifications)
                    .onChange(of: enableApplianceNotifications) { value in
                        if value {
                            requestNotificationPermission()
                        }
                    }
            }
        }
        .navigationTitle("Settings")
    }

    func saveRateToFirebase(rate: Double) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❗️User not authenticated.")
            return
        }
        
        db.collection("users").document(currentUser.uid).updateData([
            "rate": rate
        ]) { error in
            if let error = error {
                print("❗️Failed to save rate: \(error.localizedDescription)")
            } else {
                print("✅ Rate saved successfully to Firestore: \(rate)")
            }
        }
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted.")
                } else {
                    print("❌ Notification permission denied.")
                    enableApplianceNotifications = false
                    enableAISuggestions = false
                    enablePredictionNotifications = false
                }
            }
        }
    }
}
