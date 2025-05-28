//
//  HomeViewModel.swift
//  SHEMS
//
//  Created by QSCare on 2/28/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class HomeViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var totalAppliances: Int = 0
    @Published var totalBillAmount: Double = 0.0

    private let db = Firestore.firestore()

    init() {
        fetchUserData()
        
    }

    func fetchUserData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self.userName = data["name"] as? String ?? "Unknown"
                    self.userEmail = data["email"] as? String ?? "Unknown"
                    self.fetchTotalAppliances(for: userID)
                    self.fetchTotalBillAmount()
                }
            }
        }
    }

    func fetchTotalAppliances(for userId: String) {
        db.collection("users").document(userId).collection("devices").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching devices: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self.totalAppliances = snapshot?.documents.count ?? 0
            }
        }
    }


    func fetchTotalBillAmount() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching bill amount: \(error.localizedDescription)")
                return
            }
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    self.totalBillAmount = data["totalBillAmount"] as? Double ?? 0.0
                }
            }
        }
    }

    func updateUserName(newName: String) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userID).updateData(["name": newName]) { error in
            if let error = error {
                print("Error updating name: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self.userName = newName
            }
        }
    }
}
