//
//  Item.swift
//  SHEMS
//
//  Created by QSCare on 2/22/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
