import Foundation
import FirebaseFirestore
import FirebaseAuth
import SwiftUI

// Struct to represent a week range from Monday to Sunday
struct WeekRange: Identifiable, Equatable {
    let id: String
    let weekNumber: Int
    let startDate: Date
    let endDate: Date

    var description: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return "Week \(weekNumber) (\(formatter.string(from: startDate)) to \(formatter.string(from: endDate)))"
    }

    init(weekNumber: Int, startDate: Date, endDate: Date) {
        self.weekNumber = weekNumber
        self.startDate = startDate
        self.endDate = endDate
        self.id = "\(weekNumber)-\(startDate.timeIntervalSince1970)"
    }

    static func ==(lhs: WeekRange, rhs: WeekRange) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class EnergyUsageViewModel: ObservableObject {
    private var db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private var userId: String = ""

    @Published var dailyUsages: [DailyEnergyUsage] = []
    @Published var availableWeeks: [WeekRange] = []
    @Published var selectedWeek: WeekRange? = nil {
        didSet {
            objectWillChange.send()
        }
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var hourlyUsage: [HourlyEnergyUsage] = []
    @Published var monthlyEnergyUsageAllDevices = 0.0
    @Published var monthlyCostAllDevices = 0.0
    @Published var rate: Double = 0.0

    @Published var selectedMonth: String = DateFormatter().monthSymbols[Calendar.current.component(.month, from: Date()) - 1] {
        didSet {
            computeAvailableWeeks()
            calculateMonthlyTotals()
        }
    }

    init() {
        fetchUserRate()
        fetchAllDailyEnergyUsage()
    }

    deinit {
        listeners.forEach { $0.remove() }
    }

    func fetchUserRate() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        userId = uid

        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching rate: \(error)")
                return
            }

            if let data = snapshot?.data(), let rate = data["rate"] as? Double {
                DispatchQueue.main.async {
                    self.rate = rate
                }
            }
        }
    }

    func filterDailyUsageForSelectedMonth() -> [DailyEnergyUsage] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        guard let selectedDate = formatter.date(from: selectedMonth) else {
            return []
        }

        let selectedMonthIndex = calendar.component(.month, from: selectedDate)
        let selectedYear = calendar.component(.year, from: selectedDate)

        return dailyUsages.filter { usage in
            let month = calendar.component(.month, from: usage.date)
            let year = calendar.component(.year, from: usage.date)
            return month == selectedMonthIndex && year == selectedYear
        }
    }

    func getFilteredUsageForSelectedWeek() -> [DailyEnergyUsage] {
        guard let selectedWeek = selectedWeek else {
            return filterDailyUsageForSelectedMonth()
        }

        return dailyUsages.filter { usage in
            usage.date >= selectedWeek.startDate && usage.date <= selectedWeek.endDate
        }.sorted(by: { $0.date < $1.date })
    }

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func fetchAllDailyEnergyUsage() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }

        userId = uid
        let usagesRef = db.collection("users").document(userId).collection("energy_data")
        isLoading = true

        usagesRef.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false
            }

            if let error = error {
                print("Error fetching data: \(error)")
                return
            }

            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("No documents found in energy_data collection")
                return
            }

            var energyUsages: [DailyEnergyUsage] = []

            for document in documents {
                let data = document.data()
                let documentID = document.documentID
                let totalConsumption = data["total_consumption"] as? Double ?? 0.0
                let totalCost = data["total_cost"] as? Double ?? 0.0

                if let dateObject = self.dateFormatter.date(from: documentID) {
                    energyUsages.append(DailyEnergyUsage(id: documentID, date: dateObject, total_consumption: totalConsumption, total_cost: totalCost))
                }
            }

            DispatchQueue.main.async {
                self.dailyUsages = energyUsages.sorted(by: { $0.date < $1.date })
                self.computeAvailableWeeks()
                self.calculateMonthlyTotals()
            }
        }
    }

    private func computeAvailableWeeks() {
        let calendar = Calendar.current
        var weeks: [WeekRange] = []

        let selectedMonthIndex = DateFormatter().monthSymbols.firstIndex(of: selectedMonth) ?? 0
        let selectedYear = calendar.component(.year, from: Date())

        let filteredDailyUsages = dailyUsages.filter { usage in
            let month = calendar.component(.month, from: usage.date)
            let year = calendar.component(.year, from: usage.date)
            return month == (selectedMonthIndex + 1) && year == selectedYear
        }

        let grouped = Dictionary(grouping: filteredDailyUsages) { record -> Date in
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: record.date)
            return calendar.date(from: components)!
        }

        for (weekStart, _) in grouped {
            let weekNumber = calendar.component(.weekOfYear, from: weekStart)
            var startComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)
            startComponents.weekday = 2 // Monday
            guard let mondayDate = calendar.date(from: startComponents),
                  let sundayDate = calendar.date(byAdding: .day, value: 6, to: mondayDate) else { continue }

            weeks.append(WeekRange(weekNumber: weekNumber, startDate: mondayDate, endDate: sundayDate))
        }

        weeks.sort { $0.startDate < $1.startDate }

        DispatchQueue.main.async {
            self.availableWeeks = weeks
            if self.selectedWeek == nil, let firstWeek = weeks.first {
                self.selectedWeek = firstWeek
            } else if !weeks.contains(where: { $0.id == self.selectedWeek?.id }) {
                self.selectedWeek = weeks.first
            }
        }
    }

    func fetchHourlyUsage(for date: String) {
        guard !userId.isEmpty else { return }

        db.collection("users").document(userId).collection("energy_data")
            .document(date).collection("hourly_data")
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching hourly data: \(error.localizedDescription)")
                        return
                    }

                    self.hourlyUsage = snapshot?.documents.compactMap { doc in
                        guard let consumption = doc.data()["consumption"] as? Double else { return nil }
                        return HourlyEnergyUsage(hour: doc.documentID, consumption: consumption)
                    } ?? []
                }
            }
    }

    func calculateMonthlyTotals() {
        let calendar = Calendar.current
        let selectedMonthIndex = DateFormatter().monthSymbols.firstIndex(of: selectedMonth) ?? 0
        let currentYear = calendar.component(.year, from: Date())

        var totalConsumption: Double = 0.0
        var totalCost: Double = 0.0

        for usage in dailyUsages {
            let month = calendar.component(.month, from: usage.date)
            let year = calendar.component(.year, from: usage.date)

            if month == (selectedMonthIndex + 1) && year == currentYear {
                totalConsumption += usage.total_consumption
                totalCost += usage.total_cost
            }
        }

        monthlyEnergyUsageAllDevices = totalConsumption
        monthlyCostAllDevices = totalCost
    }
}
