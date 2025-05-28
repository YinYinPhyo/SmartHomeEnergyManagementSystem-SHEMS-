import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct DeviceCardView: View {
    @Binding var deviceWithEnergy: DeviceWithEnergy
    @StateObject private var viewModel = ApplianceDetailViewModel()
    @State private var isToggling = false

    private var deviceId: String {
        deviceWithEnergy.energyData?.id ?? ""
    }

    private var isOn: Bool {
        deviceWithEnergy.energyData?.isOn ?? false
    }

    private var usageTime: Int {
        deviceWithEnergy.energyData?.usageTime ?? 0
    }

    var body: some View {
        VStack {
            NavigationLink(destination: ApplianceDetailView(deviceId: deviceId)) {
                VStack {
                    Image(deviceWithEnergy.device.image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 70)
                    
                    Text(deviceWithEnergy.device.name)
                        .font(.custom("Montaga-Regular", size: 18))
                        .foregroundStyle(AppColors.accentColor)
                }
                .padding(.top, 10)
            }
            .buttonStyle(PlainButtonStyle())

            if let _ = deviceWithEnergy.energyData {
                Toggle(isOn: Binding(
                    get: { self.deviceWithEnergy.energyData?.isOn ?? false },
                    set: { newValue in
                        toggleDevice(isOn: newValue)
                    }
                )) {
                    Text(isOn ? "ON" : "OFF")
                        .fontWeight(.bold)
                }
                .toggleStyle(SwitchToggleStyle(tint: AppColors.secondaryColor))
                .disabled(isToggling)
            }

            if usageTime > 0 {
                let hours = usageTime / 60
                let minutes = usageTime % 60
                VStack {
                    Text("\(hours) H \(minutes) M")
                    Text("Today")
                }
                .padding(.bottom)
                .font(.subheadline)
                .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(width: 150, height: 230)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
    }

    private func currentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: Date())
    }

    private func toggleDevice(isOn: Bool) {
        guard let deviceId = deviceWithEnergy.device.id,
              let userId = Auth.auth().currentUser?.uid else { return }

        isToggling = true

        let deviceRef = Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("energy_data")
            .document(currentDateString())
            .collection("devices")
            .document(deviceId)

        deviceRef.updateData([
            "isOn": isOn,
            "lastUpdated": FieldValue.serverTimestamp()
        ]) { error in
            DispatchQueue.main.async {
                self.isToggling = false

                if let error = error {
                    print("Error updating device: \(error.localizedDescription)")
                    self.deviceWithEnergy.energyData?.isOn.toggle() // Revert on error
                } else {
                    self.deviceWithEnergy.energyData?.isOn = isOn
                }
            }
        }
    }
}
