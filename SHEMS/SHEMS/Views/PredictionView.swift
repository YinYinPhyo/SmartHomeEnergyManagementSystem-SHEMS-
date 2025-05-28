import SwiftUI
import Charts
import FirebaseFirestore
import FirebaseAuth


// Updated PredictionView to use the combined chart
struct PredictionView: View {
    @StateObject private var viewModel = PredictionViewModel()
    @State private var chartType: ChartType1 = .daily

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Energy Usage Predictions")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.primaryColor)
                    
                    ChartTypeSelector1(chartType: $chartType)
                    
                    if chartType == .daily {
                        CombinedDailyChartView(viewModel: viewModel)
                    } else {
                        HourlyPredictionChartView(viewModel: viewModel)
                    }
                }
                .padding(.horizontal)
            }
            .background(AppColors.appBGColor)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.fetchAllData()
            }
            .onChange(of: chartType) { newType in
                if newType == .hourly {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let currentDateString = formatter.string(from: Date())
                    viewModel.fetchHourlyData(for: currentDateString)
                }
            }
        }
    }
}

// Week selector view
struct WeekSelectionView: View {
    @ObservedObject var viewModel: PredictionViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.availableWeeks) { week in
                    Button(action: {
                        viewModel.selectedWeek = week
                    }) {
                        Text(week.description)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(viewModel.selectedWeek?.id == week.id ?
                                          AppColors.secondaryColor : Color.gray.opacity(0.2))
                            )
                            .foregroundColor(viewModel.selectedWeek?.id == week.id ? .white : .primary)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
        }
    }
}
// Combined chart view for daily data
struct CombinedDailyChartView: View {
    @ObservedObject var viewModel: PredictionViewModel
    @State private var showingLegend = true
    
    var body: some View {
        VStack {
            WeekSelectionView(viewModel: viewModel)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.filteredPredictions.isEmpty && viewModel.filteredUsages.isEmpty {
                Text("No data available for the selected week")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Consumption chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Energy Consumption (kWh)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Chart {
                        ForEach(viewModel.filteredUsages) { usage in
                           BarMark(
                                x: .value("Date", formatDate(usage.date)),
                                y: .value("Actual", usage.total_consumption)
                            )
                           .foregroundStyle(Color.red.opacity(0.5))
                           .annotation(position: .automatic) {
                                Text("\(String(format: "%.2f", usage.total_consumption))")
                                    .font(.caption2)
                                    .foregroundColor(Color.red)
                                  
                            }
                        }
                        ForEach(viewModel.filteredPredictions) { prediction in
                            LineMark(
                                x: .value("Date", formatDate(prediction.date)),
                                y: .value("Prediction", prediction.prediction)
                            )
                            .foregroundStyle(AppColors.secondaryColor)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)
                            
                            // Add annotations for prediction values
                            PointMark(
                                x: .value("Date", formatDate(prediction.date)),
                                y: .value("Prediction", prediction.prediction)
                            )
                            .annotation(position: .automatic) {
                                Text("\(String(format: "%.2f", prediction.prediction))")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.primaryColor)
                                    .padding(4)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(2)
                            }
                        }
                        
                       
                    }.frame(height: 250)

                    .padding(.vertical, 8)
                }
                
                // Energy Consumption Legend
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                        Text("Actual Usage")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppColors.secondaryColor)
                            .frame(width: 10, height: 10)
                        Text("Predicted Usage")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    if let avgPred = averagePrediction(), let avgActual = averageActual() {
                        Text("Avg: \(avgPred, specifier: "%.2f") vs \(avgActual, specifier: "%.2f") kWh")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 16)
                
                // Cost chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Energy Usage Cost ($)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Chart {
                        ForEach(viewModel.filteredPredictions) { prediction in
                            LineMark(
                                x: .value("Date", formatDate(prediction.date)),
                                y: .value("Predicted Cost", prediction.predicted_cost)
                            )
                            .foregroundStyle(AppColors.secondaryColor)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)
                            
                            // Add annotations for prediction cost values
                            PointMark(
                                x: .value("Date", formatDate(prediction.date)),
                                y: .value("Predicted Cost", prediction.predicted_cost)
                            )
                            .annotation(position: .top) {
                                Text("$\(String(format: "%.2f", prediction.predicted_cost))")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.secondaryColor)
                                    .padding(2)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(2)
                            }
                        }
                        
                        ForEach(viewModel.filteredUsages) { usage in
                           BarMark(
                                x: .value("Date", formatDate(usage.date)),
                                y: .value("Actual Cost", usage.total_cost)
                            )
                           .foregroundStyle(Color.red.opacity(0.5))
                            .annotation(position: .top) {
                                Text("$\(String(format: "%.2f", usage.total_cost))")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                    .padding(2)
                                   
                                    .cornerRadius(2)
                            }
                        }
                    }.frame(height: 250)
                        .padding(.vertical, 8)

                    
                }
                
                // Cost Legend & Summary
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                        Text("Actual Cost")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppColors.secondaryColor)
                            .frame(width: 10, height: 10)
                        Text("Predicted Cost")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    if let avgPredCost = averagePredictedCost(), let avgActualCost = averageActualCost() {
                        Text("Avg: $\(avgPredCost, specifier: "%.2f") vs $\(avgActualCost, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                  
                }
                .padding(.horizontal, 4)
                .padding(.top, 2)
            }
        }
        .padding()
    }
    
    // Format date for display on chart
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    // Calculate Y domain for energy usage chart
    private func chartYDomain() -> ClosedRange<Double> {
        let predictions = viewModel.filteredPredictions.map { $0.prediction }
        let usages = viewModel.filteredUsages.map { $0.total_consumption }
        let allValues = predictions + usages
        
        if allValues.isEmpty {
            return 0...10
        }
        
        let minValue = (allValues.min() ?? 0) * 0.9
        let maxValue = (allValues.max() ?? 10) * 1.1
        
        return minValue...maxValue
    }
    
    // Calculate Y domain for cost chart
    private func costChartYDomain() -> ClosedRange<Double> {
        let predictedCosts = viewModel.filteredPredictions.map { $0.predicted_cost }
        let actualCosts = viewModel.filteredUsages.map { $0.total_cost }
        let allCosts = predictedCosts + actualCosts
        
        if allCosts.isEmpty {
            return 0...10
        }
        
        let minValue = (allCosts.min() ?? 0) * 0.9
        let maxValue = (allCosts.max() ?? 10) * 1.1
        
        return minValue...maxValue
    }
    
    // Calculate average metrics for summary display
    private func averagePrediction() -> Double? {
        let predictions = viewModel.filteredPredictions.map { $0.prediction }
        return predictions.isEmpty ? nil : predictions.reduce(0, +) / Double(predictions.count)
    }
    
    private func averageActual() -> Double? {
        let usages = viewModel.filteredUsages.map { $0.total_consumption }
        return usages.isEmpty ? nil : usages.reduce(0, +) / Double(usages.count)
    }
    
    private func averagePredictedCost() -> Double? {
        let costs = viewModel.filteredPredictions.map { $0.predicted_cost }
        return costs.isEmpty ? nil : costs.reduce(0, +) / Double(costs.count)
    }
    
    private func averageActualCost() -> Double? {
        let costs = viewModel.filteredUsages.map { $0.total_cost }
        return costs.isEmpty ? nil : costs.reduce(0, +) / Double(costs.count)
    }
}

enum ChartType1 {
    case daily, hourly
}

struct ChartTypeSelector1: View {
    @Binding var chartType: ChartType1
    
    var body: some View {
        Picker("View", selection: $chartType) {
            Text("Daily").tag(ChartType1.daily)
            Text("Hourly").tag(ChartType1.hourly)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.vertical, 8)
    }
}


struct HourlyPredictionChartView: View {
    @ObservedObject var viewModel: PredictionViewModel
    @State private var selectedDate = Date()
    @State private var showDatePicker = false

    var startOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
    }

    var today: Date {
        return Date()
    }

    var formattedSelectedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd, EEEE"
        return dateFormatter.string(from: selectedDate)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Hourly Energy Usage & Predictions")
                .font(.headline)
                .foregroundStyle(AppColors.primaryColor)

            HStack {
                Text(formattedSelectedDate)
                    .foregroundColor(AppColors.secondaryColor)
                    .fontWeight(.semibold)
                
                Spacer()

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
            }
            .padding()
            
            if showDatePicker {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                    .padding()
                    .onChange(of: selectedDate) { newDate in
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let formattedDate = dateFormatter.string(from: newDate)
                        
                        viewModel.fetchHourlyData(for: formattedDate)
                        showDatePicker.toggle()
                    }
            }

            if viewModel.hourlyPredictions.isEmpty && viewModel.hourlyEnergyUsages.isEmpty {
                Text("No hourly data available for the selected date.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal) {
                    Chart {
                        ForEach(viewModel.hourlyPredictions) { data in
                            LineMark(
                                x: .value("Hour", data.hour),
                                y: .value("Energy", data.prediction)
                            )
                            .foregroundStyle(AppColors.secondaryColor)
                            .lineStyle(StrokeStyle(lineWidth: 2))
//                            .symbol {
//                                Circle()
//                                    .fill(AppColors.secondaryColor)
//                                    .frame(width: 8, height: 8)
//                            }
                            .interpolationMethod(.catmullRom)
                            
                            // Add annotations for prediction cost values
                            PointMark(
                                x: .value("Hour", data.hour),
                                y: .value("Energy", data.prediction)
                            )
                            .annotation(position: .top) {
                                Text("\(String(format: "%.2f", data.prediction))")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.secondaryColor)
                                    .padding(2)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(2)
                            }
                        }
//                        ForEach(viewModel.hourlyPredictions) { data in
//                            LineMark(
//                                x: .value("Hour", data.hour),
//                                y: .value("Energy", data.prediction)
//                            )
//                            .foregroundStyle(AppColors.secondaryColor.opacity(0.5))
//                            .annotation(position: .bottom) {
//                                Text("\(data.prediction, specifier: "%.1f")")
//                                    .font(.caption2)
//                                    .foregroundColor(AppColors.secondaryColor)
//                                    
//                            }
//                        }
                        
                        ForEach(viewModel.hourlyEnergyUsages) { data in
                            BarMark(
                                x: .value("Hour", data.hour),
                                y: .value("Energy", data.consumption)
                            )
                            .foregroundStyle(Color.red.opacity(0.5))
                            .annotation(position: .bottom) {
                                Text("\(data.consumption, specifier: "%.2f")")
                                    .font(.caption2)
                                    .foregroundColor(Color.red)
                                    
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
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
                Text("Actual")
                    .font(.caption)
                    .foregroundColor(Color.red)
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppColors.secondaryColor)
                    .frame(width: 10, height: 10)
                Text("Predicted")
                    .font(.caption)
                    .foregroundColor(AppColors.secondaryColor)
                Spacer()
                Text("kWh")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

