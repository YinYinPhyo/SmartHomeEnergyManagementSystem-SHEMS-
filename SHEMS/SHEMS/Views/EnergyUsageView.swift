import SwiftUI
import Charts

struct EnergyUsageView: View {
    @StateObject private var viewModel = EnergyUsageViewModel()
    @State private var selectedMonth: String = getCurrentMonthAndYear()
    @State private var chartType: ChartType = .daily
    
    // Helper function to get the current month and year in the format "Month, Year"
    static func getCurrentMonthAndYear() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM, yyyy" // Ensures correct format without comma in the year
        return dateFormatter.string(from: Date())
    }

    func getMonthDateRange(from selectedMonth: String) -> (Date, Date)? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM, yyyy"
        
        guard let monthDate = dateFormatter.date(from: selectedMonth) else {
            return nil
        }
        
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: monthDate)!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))!
        let endOfMonth = calendar.date(byAdding: .day, value: range.count - 1, to: startOfMonth)!
        
        return (startOfMonth, endOfMonth)
    }

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Energy Usage")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.primaryColor)
                    
                    MonthSelectorView(selectedMonth: $selectedMonth, viewModel: viewModel)
                    
                    ChartTypeSelectorView(chartType: $chartType)
                    
                    if viewModel.isLoading {
                        ProgressView().padding()
                    } else if viewModel.dailyUsages.isEmpty {
                        Text("No energy data available")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        if chartType == .daily {
                            DailyUsageChartView(viewModel: viewModel)
                        } else {
                            if let (startDate, endDate) = getMonthDateRange(from: selectedMonth) {
                                    HourlyUsageChartView(viewModel: viewModel, startDate: startDate, endDate: endDate)
                                } else {
                                    Text("Invalid month selection")
                                }
                        }
                    }
                    
                    TotalEnergyUsageView(viewModel: viewModel, selectedMonth: $selectedMonth)
                }
                .padding()
            }
            .background(AppColors.appBGColor)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchAllDailyEnergyUsage()
                viewModel.fetchUserRate()
            }
            .onChange(of: selectedMonth) { newMonth in
                // Parse the month from the formatted string (e.g. "March, 2025")
                if let commaIndex = newMonth.firstIndex(of: ",") {
                    let month = String(newMonth[..<commaIndex]).trimmingCharacters(in: .whitespaces)
                    viewModel.selectedMonth = month
                }
            }
            .onChange(of: chartType) { newType in
                if newType == .hourly {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let currentDateString = formatter.string(from: Date())
                    viewModel.fetchHourlyUsage(for: currentDateString)
                }
            }
        }
        
    }
    
  
}

enum ChartType {
    case daily, hourly
}

struct ChartTypeSelectorView: View {
    @Binding var chartType: ChartType
    
    var body: some View {
        Picker("Select Chart", selection: $chartType) {
            Text("Daily").tag(ChartType.daily)
            Text("Hourly").tag(ChartType.hourly)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
}

struct HourlyUsageChartView: View {
    @ObservedObject var viewModel: EnergyUsageViewModel
        var startDate: Date
        var endDate: Date
        @State private var selectedDate = Date()
        @State private var showDatePicker = false
    
    // Computed properties to get date range dynamically
    var startOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
    }
        
    var today: Date {
        return Date()
    }
    
    // Computed property to format the selected date with day of the week
    var formattedSelectedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd, EEEE"
        return dateFormatter.string(from: selectedDate)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Hourly Energy Usage")
                .font(.headline)
                .foregroundStyle(AppColors.primaryColor)
            
            HStack {
                // Display the formatted selected date with day of the week
                Text(formattedSelectedDate)
                    .foregroundColor(AppColors.secondaryColor)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Button to show/hide the DatePicker with a button style
                Button(action: {
                    withAnimation {
                        showDatePicker.toggle()
                    }
                }) {
                    Text("Select Date")
                        .foregroundColor(AppColors.secondaryColor)
                        .fontWeight(.semibold)
                }
                .buttonStyle(BorderedButtonStyle())
            }.padding()
                        
            // Conditionally show the DatePicker according to the selected month
            if showDatePicker {
                DatePicker("Select Date", selection: $selectedDate, in: startDate...endDate, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .padding()
                    .onChange(of: selectedDate) { newDate in
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let formattedDate = dateFormatter.string(from: newDate)
                        viewModel.fetchHourlyUsage(for: formattedDate)
                        showDatePicker.toggle()
                    }

            }
            
            VStack {
                ScrollView(.horizontal) {
                    Chart {
                        ForEach(viewModel.hourlyUsage, id: \.hour) { data in
                            BarMark(
                                x: .value("Hour", data.hour),
                                y: .value("Energy", data.consumption)
                            )
                            .foregroundStyle(AppColors.secondaryColor)
                            .annotation(position: .automatic) {
                                Text("\(String(format: "%.2f", data.consumption))")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.secondaryColor)
                            }
                        }
                    }
                    .frame(width: max(1000, UIScreen.main.bounds.width), height: 200)
                    .padding(.horizontal)
                    .padding(.top)
                }
                .scrollIndicators(.hidden)
            }

            HStack {
                Spacer()
                Text("kWh")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}



struct TotalEnergyUsageView: View {
    @ObservedObject var viewModel: EnergyUsageViewModel
    @Binding var selectedMonth: String
    
    var body: some View {
        VStack {
            HStack {
                Text("Total Energy Usage & Bill")
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryColor)
                Spacer()
                Image(systemName: "bolt.circle.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
            }
            .padding()
            
            HStack {
                VStack {
                    Text("\(viewModel.monthlyEnergyUsageAllDevices, specifier: "%.2f") kWh")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(AppColors.textColor1)
                
                    Divider()
                        .frame(width: 100)
                        .background(AppColors.secondaryColor)
                
                    Text("$\(viewModel.monthlyCostAllDevices, specifier: "%.2f")")
                        .font(.title3)
                        .bold()
                        .foregroundStyle(AppColors.textColor1)
                }.frame(maxWidth: .infinity)
                
                Spacer()
                
                Image("Bill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            }.padding(.horizontal)
            
            Text("Monthly (\(selectedMonth))")
                .foregroundStyle(AppColors.textColor1)
 
            Text("Rate: \(viewModel.rate, specifier: "%.2f") $/kWh")
                .foregroundStyle(AppColors.primaryColor)
                .padding(.bottom)
                
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

struct MonthSelectorView: View {
    @Binding var selectedMonth: String
    @ObservedObject var viewModel: EnergyUsageViewModel
    let months = DateFormatter().monthSymbols ?? []
    
    var body: some View {
        let currentYear = Calendar.current.component(.year, from: Date())
        
        Menu {
            ForEach(months, id: \.self) { month in
                Button(action: {
                    selectedMonth = "\(month), \(currentYear)" // Format without comma in year
                    viewModel.selectedMonth = month // Update view model directly
                }) {
                    Text("\(month)") // Display without comma in year
                }
            }
        } label: {
            HStack {
                Text(selectedMonth)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primaryColor)

                Spacer()

                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(AppColors.primaryColor)
            }
            .padding()
            .background(Color.white)
           
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
}

struct WeekSelectorView: View {
    @ObservedObject var viewModel: EnergyUsageViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.availableWeeks) { week in
                    Button(action: {
                        viewModel.selectedWeek = week
                    }) {
                        Text(week.description)
                            .font(.caption)
                            .padding(8)
                            .background(viewModel.selectedWeek?.id == week.id ?
                                      AppColors.secondaryColor : Color.gray.opacity(0.2))
                            .foregroundColor(viewModel.selectedWeek?.id == week.id ? .white : .primary)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct DailyUsageChartView: View {
    @ObservedObject var viewModel: EnergyUsageViewModel
    
    // Weekdays starting from Monday
    let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Daily Energy Usage")
                .font(.headline)
                .foregroundStyle(AppColors.primaryColor)
                .padding(.bottom, 5)
            
            // Week selector using viewModel's available weeks and selectedWeek binding
            WeekSelectorView(viewModel: viewModel)
            
            // Use the filtered data based on selected week
            let filteredUsage = viewModel.getFilteredUsageForSelectedWeek()
            
            Chart {
                ForEach(filteredUsage, id: \.id) { usage in
                    let formattedDate = formatDate(usage.date)
                    BarMark(
                        x: .value("Date", formattedDate),
                        y: .value("Energy", usage.total_consumption)
                    )
                    .foregroundStyle(AppColors.secondaryColor)
                    .annotation(position: .automatic) {
                        Text("\(String(format: "%.2f", usage.total_consumption))")
                            .font(.caption2)
                            .foregroundColor(AppColors.secondaryColor)
                    }
                }
            }
            .frame(height: 200)
            
            HStack {
                Spacer()
                Text("kWh")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Helper function to format the date to "MM/dd"
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        return dateFormatter.string(from: date)
    }
}

// Helper for alerts
struct AlertItem: Identifiable {
    var id = UUID()
    var message: String
}


