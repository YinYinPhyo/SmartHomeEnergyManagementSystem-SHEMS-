import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

// Updated ViewModel with proper week selection handling
class PredictionViewModel: ObservableObject {
    private var db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private let userId: String
    private var lastKnownPredictionCount: Int = 0 //notification

    
    @Published var isLoading: Bool = true
    @Published var dailyPredictions: [DailyEnergyPrediction] = []
    @Published var dailyEnergyUsages: [DailyEnergyUsage] = []
    @Published var hourlyPredictions: [HourlyEnergyPrediction] = []
    @Published var hourlyEnergyUsages: [HourlyEnergyUsage] = []
    
    @Published var availableWeeks: [WeekRange] = []
    @Published var selectedWeek: WeekRange? = nil {
        didSet {
            print("Selected week: \(selectedWeek?.description ?? "none")")
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    init() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Error: User not authenticated")
            self.userId = ""
            return
        }
        self.userId = uid
    }
    
    deinit {
        listeners.forEach { $0.remove() }
    }
    
    func fetchAllData() {
        isLoading = true
        
        fetchDailyPredictions { [weak self] in
            self?.fetchDailyEnergyUsage {
                self?.generateWeekRanges()
                self?.isLoading = false
            }
        }
    }
    
    // Fetch daily predictions from Firestore
    func fetchDailyPredictions(completion: @escaping () -> Void) {
        guard !userId.isEmpty else {
            completion()
            return
        }
        
        db.collection("users").document(userId).collection("predictions")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { completion(); return }
                
                if let error = error {
                    print("Error fetching prediction data: \(error.localizedDescription)")
                    completion()
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No prediction documents found")
                    completion()
                    return
                }
                
                print("Found \(documents.count) prediction documents")
                
                let parsedPredictions = documents.compactMap { doc -> DailyEnergyPrediction? in

                    guard let dateString = doc.documentID as String?,
                          let date = self.dateFormatter.date(from: dateString),
                          let data = doc.data() as [String: Any]?,
                          let predictedCost = data["predicted_cost"] as? Double,
                          let prediction = data["total_prediction"] as? Double else {
                        print("Failed to parse prediction document: \(doc.documentID)")
                        return nil
                    }
                    
                    return DailyEnergyPrediction(
                        id: doc.documentID,
                        date: date,
                        predicted_cost: predictedCost,
                        prediction: prediction
                    )
                }
                let newCount = parsedPredictions.count

                // Notify only if user receives more than 1 new prediction compared to before
                if newCount > lastKnownPredictionCount + 1 {
                    self.sendPredictionNotification(newCount: newCount)
                }

                self.lastKnownPredictionCount = newCount
                self.dailyPredictions = parsedPredictions

                
                print("Successfully parsed \(self.dailyPredictions.count) prediction records")
                completion()
            }
    }
    func sendPredictionNotification(newCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🔮 New Predictions Available"
        content.body = "You have new energy usage predictions for multiple days. Tap to view the forecast!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // immediate
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send prediction notification: \(error.localizedDescription)")
            } else {
                print("✅ Prediction notification sent.")
            }
        }
    }
    
    // Fetch daily energy usage from Firestore
    func fetchDailyEnergyUsage(completion: @escaping () -> Void) {
        guard !userId.isEmpty else {
            completion()
            return
        }
        
        db.collection("users").document(userId).collection("energy_data")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { completion(); return }
                
                if let error = error {
                    print("Error fetching energy usage data: \(error.localizedDescription)")
                    completion()
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No energy usage documents found")
                    completion()
                    return
                }
                
                print("Found \(documents.count) energy usage documents")
                
                self.dailyEnergyUsages = documents.compactMap { doc -> DailyEnergyUsage? in
                    guard let dateString = doc.documentID as String?,
                          let date = self.dateFormatter.date(from: dateString),
                          let data = doc.data() as [String: Any]?,
                          let totalConsumption = data["total_consumption"] as? Double,
                          let totalCost = data["total_cost"] as? Double else {
                        print("Failed to parse usage document: \(doc.documentID)")
                        return nil
                    }
                    
                    return DailyEnergyUsage(
                        id: doc.documentID,
                        date: date,
                        total_consumption: totalConsumption,
                        total_cost: totalCost
                    )
                }
                
                print("Successfully parsed \(self.dailyEnergyUsages.count) usage records")
                completion()
            }
    }
    
    // Generate week ranges from available data
    private func generateWeekRanges() {
        let calendar = Calendar.current
        
        // Combine all dates from both predictions and usages
        let allDates = Set(dailyPredictions.map { $0.date } + dailyEnergyUsages.map { $0.date }).sorted()
        
        if allDates.isEmpty {
            self.availableWeeks = []
            self.selectedWeek = nil
            return
        }
        
        // Group dates by week
        var weekGroups: [Int: [Date]] = [:]
        
        for date in allDates {
            let weekOfYear = calendar.component(.weekOfYear, from: date)
            let yearComponent = calendar.component(.year, from: date)
            // Combine year and week for unique identification
            let weekKey = yearComponent * 100 + weekOfYear
            
            if weekGroups[weekKey] == nil {
                weekGroups[weekKey] = []
            }
            weekGroups[weekKey]?.append(date)
        }
        
        // Create week ranges from grouped dates
        self.availableWeeks = weekGroups.keys.sorted().compactMap { weekKey in
            guard let dates = weekGroups[weekKey],
                  let firstDate = dates.min(),
                  let lastDate = dates.max() else {
                return nil
            }
            
            // Extract week number from the key
            let weekNumber = weekKey % 100
            
            return WeekRange(
                weekNumber: weekNumber,
                startDate: calendar.startOfDay(for: firstDate),
                endDate: calendar.startOfDay(for: lastDate)
            )
        }
        
        // Select the most recent week by default
        if let mostRecentWeek = self.availableWeeks.last {
            self.selectedWeek = mostRecentWeek
        }
        
        print("Generated \(self.availableWeeks.count) week ranges")
    }
    
    // Filter predictions based on selected week
    var filteredPredictions: [DailyEnergyPrediction] {
        guard let selectedWeek = selectedWeek else { return [] }
        
        return dailyPredictions.filter { prediction in
            let date = prediction.date
            let startOfDay = Calendar.current.startOfDay(for: date)
            return startOfDay >= selectedWeek.startDate && startOfDay <= selectedWeek.endDate
        }
    }
    
    // Filter usages based on selected week
    var filteredUsages: [DailyEnergyUsage] {
        guard let selectedWeek = selectedWeek else { return [] }
        
        return dailyEnergyUsages.filter { usage in
            let date = usage.date
            let startOfDay = Calendar.current.startOfDay(for: date)
            return startOfDay >= selectedWeek.startDate && startOfDay <= selectedWeek.endDate
        }
    }
    
    // Fetch hourly data (same as before)
    func fetchHourlyData(for date: String) {
        fetchHourlyPrediction(for: date)
        fetchHourlyUsage(for: date)
    }
    
    // Fetch hourly prediction data
        func fetchHourlyPrediction(for date: String) {
            guard !userId.isEmpty else { return }
            
            db.collection("users").document(userId).collection("predictions")
                .document(date).collection("hourly_prediction")
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error fetching hourly prediction data: \(error.localizedDescription)")
                        return
                    }
                    
                    self.hourlyPredictions = snapshot?.documents.compactMap { doc in
                        guard let data = doc.data() as [String: Any]?,
                              let predictedCost = data["predicted_cost"] as? Double,
                              let prediction = data["prediction"] as? Double else {
                            return nil
                        }
                        
                        return HourlyEnergyPrediction(
                            hour: doc.documentID,
                            predicted_cost: predictedCost,
                            prediction: prediction
                        )
                    } ?? []
                }
        }
    
    // Fetch hourly usage data
        func fetchHourlyUsage(for date: String) {
            guard !userId.isEmpty else { return }
            
            db.collection("users").document(userId).collection("energy_data")
                .document(date).collection("hourly_data")
                .getDocuments { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error fetching hourly usage data: \(error.localizedDescription)")
                        return
                    }
                    
                    self.hourlyEnergyUsages = snapshot?.documents.compactMap { doc in
                        guard let data = doc.data() as [String: Any]?,
                              let consumption = data["consumption"] as? Double else {
                            return nil
                        }
                        
                        return HourlyEnergyUsage(
                            hour: doc.documentID,
                            consumption: consumption
                           
                        )
                    } ?? []
                }
        }
}
