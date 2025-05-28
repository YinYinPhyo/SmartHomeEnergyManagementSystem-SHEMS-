//
//  PredictionData.swift
//  SHEMS
//
//  Created by QSCare on 3/30/25.
//

import Foundation
import FirebaseCore

struct DailyEnergyPrediction: Identifiable {
    var id: String
    var date: Date
    var predicted_cost: Double
    var prediction: Double
}

struct HourlyEnergyPrediction: Identifiable {
    var id: String { hour }
    var hour: String
    var predicted_cost: Double
    var prediction: Double
}

