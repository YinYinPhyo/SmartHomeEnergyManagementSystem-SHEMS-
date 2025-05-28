//
//  AISuggestionViewModel.swift
//  SHEMS
//
//  Created by QSCare on 4/4/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

class AISuggestionViewModel: ObservableObject {
    @Published var aiSuggestions: [AISuggestion] = []
    @Published var groupedSuggestions: [String: [AISuggestion]] = [:] // Grouped by date
    @Published var selectedDate: String = ""
    private var lastKnownSuggestionTimestamp: Date? //Notification

    private let db = Firestore.firestore()
    private var userId: String = ""

    init() {
        if let uid = Auth.auth().currentUser?.uid {
            self.userId = uid
            fetchAISuggestions()
        } else {
            print("Error: User not authenticated")
        }
    }

    func fetchAISuggestions() {
        guard !userId.isEmpty else {
            print("Error: No user ID available")
            return
        }

        db.collection("users").document(userId).collection("insights")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching AI suggestions: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                DispatchQueue.main.async {
//                    let suggestions = documents.compactMap { doc -> AISuggestion? in
//                        try? doc.data(as: AISuggestion.self)
//                    }
                    let suggestions = documents.compactMap { doc -> AISuggestion? in
                        try? doc.data(as: AISuggestion.self)
                    }.sorted(by: { $0.timestamp > $1.timestamp }) // Sort descending by timestamp

                    // 🔔 Trigger notification if there's a new suggestion
                    if let latest = suggestions.first {
                        if let last = self.lastKnownSuggestionTimestamp {
                            if latest.timestamp > last {
                                self.sendAISuggestionNotification()
                            }
                        } else {
                            // First time loading
                            self.sendAISuggestionNotification()
                        }
                        self.lastKnownSuggestionTimestamp = latest.timestamp
                    }


                    self.aiSuggestions = suggestions

                    // Group suggestions by date (yyyy-MM-dd format)
                    self.groupedSuggestions = Dictionary(grouping: suggestions) { suggestion in
                        self.formattedDate(suggestion.timestamp, format: "yyyy-MM-dd")
                    }

                    // Set default selected date to the latest available date
                    if let latestDate = self.groupedSuggestions.keys.sorted().last {
                        self.selectedDate = latestDate
                    }
                }
            }
    }
    func sendAISuggestionNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🌞 New Energy Tip Available"
        content.body = "Your personalized AI energy-saving suggestion has been generated. Tap to view it!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Show immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send local notification: \(error.localizedDescription)")
            } else {
                print("✅ AI suggestion notification sent.")
            }
        }
    }


    func formattedDate(_ date: Date, format: String = "MMM dd, yyyy - HH:mm") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
