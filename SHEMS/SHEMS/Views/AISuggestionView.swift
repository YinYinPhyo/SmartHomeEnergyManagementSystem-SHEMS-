import SwiftUI

struct AISuggestionView: View {
    @StateObject private var viewModel = AISuggestionViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("AI Suggestions")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.primaryColor)
                    
                    // Date Picker (Dropdown)
                    HStack {
                        Text("Select Date:")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.primaryColor)
                        
                        Picker("Select Date", selection: $viewModel.selectedDate) {
                            ForEach(viewModel.groupedSuggestions.keys.sorted(), id: \.self) { date in
                                Text(date).tag(date)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                    }
                    
                    // Display suggestions based on selected date
                    if let suggestions = viewModel.groupedSuggestions[viewModel.selectedDate], !suggestions.isEmpty {
                        ForEach(suggestions) { suggestion in
                            AISuggestionCard(suggestion: suggestion)
                        }
                    } else {
                        Text("No AI suggestions available for this date.")
                            .foregroundColor(.gray)
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .background(AppColors.appBGColor)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Card View for Each Suggestion
struct AISuggestionCard: View {
    let suggestion: AISuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🤖 Source: \(suggestion.source)")
                .font(.headline)
            Text("📅 Time: \(formattedDate(suggestion.timestamp))")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("💡 Suggestions")
                    .font(.headline)
                    .bold()
                ForEach(suggestion.suggestions, id: \.self) { text in
                    let parts = text.split(separator: ": ", maxSplits: 1).map { String($0) }
                    VStack(alignment: .leading, spacing: 4) {
                        if parts.count == 2 {
                            Text(parts[0]) // Title
                                .font(.headline)
                                .bold()
                                .foregroundColor(AppColors.primaryColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(parts[1]) // Body
                                .font(.body)
                                .foregroundColor(AppColors.textColor1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text(text) // Display full text if no colon is found
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 4)
                }
            }
        }
        .padding(.bottom, 10)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd, yyyy - HH:mm"
        return formatter.string(from: date)
    }
}
