

import FirebaseFirestore


// MARK: - Device Model
struct Device: Identifiable, Codable {
    var id: String? // Firestore auto-generated ID
    var name: String
    var image: String
    var category: String
    
}
// MARK: - DeviceWithEnergy Model
struct DeviceWithEnergy: Identifiable, Decodable {
    var id: String { device.id ?? UUID().uuidString }
    var device: Device
    var energyData: EnergyData?
    
    enum CodingKeys: String, CodingKey {
        case device
        case energyData
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        device = try container.decode(Device.self, forKey: .device)
        energyData = try container.decodeIfPresent(EnergyData.self, forKey: .energyData)
    }
    
    // Regular initializer
    init(device: Device, energyData: EnergyData? = nil) {
        self.device = device
        self.energyData = energyData
    }
}
