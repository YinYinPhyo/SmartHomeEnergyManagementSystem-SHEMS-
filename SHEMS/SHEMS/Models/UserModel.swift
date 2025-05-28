
import Foundation

struct UserModel: Codable {
    var uid: String
    var name: String
    var email: String
    var latitude: Double?  // New field for location data
    var longitude: Double? // New field for location data
    var rate: Double?

    // Custom initializer to handle missing values
    init(uid: String, name: String?, email: String?, latitude: Double?, longitude: Double?, rate: Double?) {
        self.uid = uid
        self.name = name ?? "Unknown"
        self.email = email ?? "No email provided"
        self.latitude = latitude 
        self.longitude = longitude
        self.rate = rate
    }
    
    // Convenience initializer for Firestore data retrieval
    init(from document: [String: Any], id: String) {
        self.uid = id
        self.name = document["name"] as? String ?? "Unknown"
        self.email = document["email"] as? String ?? "No email provided"
        self.latitude = document["latitude"] as? Double
        self.longitude = document["longitude"] as? Double
        self.rate = document["rate"] as? Double
    }
}
