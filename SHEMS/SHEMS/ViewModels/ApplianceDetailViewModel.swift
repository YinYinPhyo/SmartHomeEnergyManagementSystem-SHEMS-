import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UserNotifications


class ApplianceDetailViewModel: ObservableObject {
    @Published var device: DeviceWithEnergy?
    @Published var isLoading: Bool = true
    @Published var userRate: Double? = nil

    private var db = Firestore.firestore()
    private var energyDataListener: ListenerRegistration?

    func fetchDevice(deviceId: String) {
        guard let user = Auth.auth().currentUser else { return }
        let userId = user.uid

        let deviceRef = db.collection("users").document(userId).collection("devices").document(deviceId)
        let energyDataRef = db.collection("users").document(userId).collection("energy_data").document(currentDateString()).collection("devices").document(deviceId)

        // Fetch device info once
        deviceRef.getDocument { document, error in
            guard let document = document, document.exists else {
                print("Device not found or error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let data = document.data() ?? [:]
            let fetchedDevice = Device(
                id: document.documentID,
                name: data["name"] as? String ?? "Unknown Device",
                image: data["image"] as? String ?? "AppLogo.png",
                category: data["category"] as? String ?? "Other"
            )

            // Set up real-time listener for energy data
            self.energyDataListener?.remove() // Ensure only one listener
            self.energyDataListener = energyDataRef.addSnapshotListener { energyDoc, error in
                guard let energyDoc = energyDoc, energyDoc.exists, let data = energyDoc.data() else {
                    print("No energy data found or error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }

//                let energyData = EnergyData(
//                    id: energyDoc.documentID,
//                    isOn: data["isOn"] as? Bool ?? false,
//                    usageTime: data["usageTime"] as? Int ?? 0,
//                    consumption: data["consumption"] as? Double ?? 0.0,
//                    last_updated: (data["last_updated"] as? Timestamp)?.dateValue() ?? Date(),
//                    cost: data["cost"] as? Double ?? 0.0
//                )
//
//                DispatchQueue.main.async {
//                    self.device = DeviceWithEnergy(device: fetchedDevice, energyData: energyData)
//                    self.isLoading = false
//                }
                
                let newIsOn = data["isOn"] as? Bool ?? false
                let energyData = EnergyData(
                    id: energyDoc.documentID,
                    isOn: newIsOn,
                    usageTime: data["usageTime"] as? Int ?? 0,
                    consumption: data["consumption"] as? Double ?? 0.0,
                    last_updated: (data["last_updated"] as? Timestamp)?.dateValue() ?? Date(),
                    cost: data["cost"] as? Double ?? 0.0
                )

                DispatchQueue.main.async {
                    if let oldIsOn = self.device?.energyData?.isOn, oldIsOn != newIsOn {
                        self.sendLocalNotification(for: fetchedDevice.name, status: newIsOn)
                    }
                    
                    self.device = DeviceWithEnergy(device: fetchedDevice, energyData: energyData)
                    self.isLoading = false
                }

            }
                
        }
    }

    func fetchUserRate() {
        guard let user = Auth.auth().currentUser else { return }
        let userId = user.uid

        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let rate = data?["rate"] as? Double
                DispatchQueue.main.async {
                    self.userRate = rate
                }
            } else {
                print("User document not found or error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    func sendLocalNotification(for deviceName: String, status: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "Smart Home Energy"
        content.body = "Device '\(deviceName)' was automatically turned \(status ? "ON" : "OFF")."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // Sends immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error showing notification: \(error.localizedDescription)")
            } else {
                print("✅ Local notification sent")
            }
        }
    }


    func updateDevicePowerState(deviceId: String, isOn: Bool) {
        guard let user = Auth.auth().currentUser else { return }
        let userId = user.uid

        let energyDataRef = db.collection("users")
            .document(userId)
            .collection("energy_data")
            .document(currentDateString())
            .collection("devices")
            .document(deviceId)

        energyDataRef.updateData([
            "isOn": isOn,
            "last_updated": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error updating power state: \(error.localizedDescription)")
            } else {
                print("Power state updated successfully")
            }
        }
    }

    func stopListening() {
        energyDataListener?.remove()
    }

    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
