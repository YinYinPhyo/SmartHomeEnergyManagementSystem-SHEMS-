//
//  EnergyData.swift
//  SHEMS
//
//  Created by QSCare on 3/19/25.
//

import FirebaseFirestore


// MARK: - Device Model
struct EnergyData: Identifiable, Codable {
    var id: String?
    var isOn: Bool
    var usageTime: Int
    var consumption: Double //each device consumption daily
    var last_updated: Date
    var cost: Double //each device cost daily
}
// Data models (simplified)
struct DailyEnergyUsage: Identifiable {
    var id: String
    var date: Date
    var total_consumption: Double
    var total_cost: Double
}

struct EnergyBill: Codable {
    var totalConsumption: Double
    var cost: Double
    var startDate: Date
    var endDate: Date
    
    enum CodingKeys: String, CodingKey {
        case totalConsumption = "total_consumption"
        case cost
        case startDate = "start_date"
        case endDate = "end_date"
    }
}
struct HourlyEnergyUsage: Identifiable {
    var id: String { hour }
    var hour: String
    var consumption: Double
   
}


