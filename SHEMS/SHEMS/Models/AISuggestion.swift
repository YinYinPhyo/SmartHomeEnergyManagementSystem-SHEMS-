//
//  Untitled.swift
//  SHEMS
//
//  Created by QSCare on 4/4/25.
//

import Foundation
import FirebaseFirestore

struct AISuggestion: Identifiable, Codable {
    @DocumentID var id: String? // Firestore document ID
    let source: String
    let suggestions: [String]
    let timestamp: Date
    
    // Custom initializer to handle Firestore timestamp conversion
    init(id: String? = nil, source: String, suggestions: [String], timestamp: Date) {
        self.id = id
        self.source = source
        self.suggestions = suggestions
        self.timestamp = timestamp
    }
}
