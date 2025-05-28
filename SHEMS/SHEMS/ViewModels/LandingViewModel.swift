import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - LandingViewModel
class LandingViewModel: ObservableObject {
    @Published var userName: String = "Guest"
    @Published var devices: [DeviceWithEnergy] = []
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var devicesListener: ListenerRegistration?
    private var energyDataListener: ListenerRegistration?
    
    func fetchUserData() {
        guard let user = Auth.auth().currentUser else { return }
        let userId = user.uid
        
        db.collection("users").document(userId).getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                DispatchQueue.main.async {
                    self.userName = data["name"] as? String ?? "Guest"
                }
            }
        }
        
        fetchDevicesAndEnergyData(userId: userId)
    }

    func updateDeviceToggleState(deviceId: String, isOn: Bool) {
        if let index = devices.firstIndex(where: { $0.device.id == deviceId }) {
            devices[index].energyData?.isOn = isOn
        }
    }

    func fetchDevicesAndEnergyData(userId: String) {
        let devicesRef = db.collection("users").document(userId).collection("devices")
        let energyDataRef = db.collection("users").document(userId).collection("energy_data")
            .document(currentDateString()).collection("devices")
        
        // Fetch devices with energy data initially
        devicesRef.getDocuments { snapshot, error in
            if let error = error {
                self.errorMessage = "Error fetching devices: \(error.localizedDescription)"
                return
            }
            
            guard let snapshot = snapshot else { return }
            
            let devices = snapshot.documents.compactMap { doc -> Device? in
                let data = doc.data()
                return Device(
                    id: doc.documentID,
                    name: data["name"] as? String ?? "Unknown Device",
                    image: data["image"] as? String ?? "AppLogo.png",
                    category: data["category"] as? String ?? "Other"
                )
            }
            
            var devicesWithEnergy: [DeviceWithEnergy] = []
            let dispatchGroup = DispatchGroup()
            
            for device in devices {
                dispatchGroup.enter()
                energyDataRef.document(device.id!).getDocument { energyDoc, _ in
                    let energyData = energyDoc?.data().flatMap { data in
                        EnergyData(
                            id: energyDoc?.documentID,
                            isOn: data["isOn"] as? Bool ?? false,
                            usageTime: data["usageTime"] as? Int ?? 0,
                            consumption: data["consumption"] as? Double ?? 0.0,
                            last_updated: (data["last_updated"] as? Timestamp)?.dateValue() ?? Date(),
                            cost: data["cost"] as? Double ?? 0.0
                        )
                    }
                    
                    DispatchQueue.main.async {
                        devicesWithEnergy.append(DeviceWithEnergy(device: device, energyData: energyData))
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.devices = devicesWithEnergy
            }
        }
        
        // Real-time listener for device changes
        devicesListener = devicesRef.addSnapshotListener { snapshot, error in
            if let error = error {
                self.errorMessage = "Error listening for device changes: \(error.localizedDescription)"
                return
            }
            
            guard let snapshot = snapshot else { return }
            var updatedDevicesWithEnergy: [DeviceWithEnergy] = []
            let dispatchGroup = DispatchGroup()
            
            for document in snapshot.documents {
                let data = document.data()
                let device = Device(
                    id: document.documentID,
                    name: data["name"] as? String ?? "Unknown Device",
                    image: data["image"] as? String ?? "AppLogo.png",
                    category: data["category"] as? String ?? "Other"
                )
                
                dispatchGroup.enter()
                energyDataRef.document(device.id!).getDocument { energyDoc, _ in
                    let energyData = energyDoc?.data().flatMap { data in
                        EnergyData(
                            id: energyDoc?.documentID,
                            isOn: data["isOn"] as? Bool ?? false,
                            usageTime: data["usageTime"] as? Int ?? 0,
                            consumption: data["consumption"] as? Double ?? 0.0,
                            last_updated: (data["last_updated"] as? Timestamp)?.dateValue() ?? Date(),
                            cost: data["cost"] as? Double ?? 0.0
                        )
                    }
                    
                    DispatchQueue.main.async {
                        updatedDevicesWithEnergy.append(DeviceWithEnergy(device: device, energyData: energyData))
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.devices = updatedDevicesWithEnergy
            }
        }
        
        // Real-time listener for energy data status updates
        energyDataListener = energyDataRef.addSnapshotListener { snapshot, error in
            if let error = error {
                self.errorMessage = "Error listening for energy data updates: \(error.localizedDescription)"
                return
            }

            guard let docs = snapshot?.documents else { return }

            DispatchQueue.main.async {
                for doc in docs {
                    guard let index = self.devices.firstIndex(where: { $0.device.id == doc.documentID }) else { continue }

                    let data = doc.data()
                    let updatedEnergyData = EnergyData(
                        id: doc.documentID,
                        isOn: data["isOn"] as? Bool ?? false,
                        usageTime: data["usageTime"] as? Int ?? 0,
                        consumption: data["consumption"] as? Double ?? 0.0,
                        last_updated: (data["last_updated"] as? Timestamp)?.dateValue() ?? Date(),
                        cost: data["cost"] as? Double ?? 0.0
                    )

                    self.devices[index].energyData = updatedEnergyData
                }
            }
        }
    }

    // Stop listening to Firestore updates
    func stopListening() {
        devicesListener?.remove()
        energyDataListener?.remove()
    }

    private func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

