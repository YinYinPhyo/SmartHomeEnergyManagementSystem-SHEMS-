import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var appState: AppState  // Access the AppState environment object
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var viewModel1 = EnergyUsageViewModel()

        @State private var newName: String = ""
        @State private var isEditing: Bool = false
    @State private var navigateToUsage = false
    @State private var navigateToPrediction = false
    @State private var navigateToSuggestion = false
    @State private var navigateToAbout = false
    @State private var navigateToSettings = false
    
    var body: some View {
        ZStack {
            Image("BG")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 16) {
            
                        // Header Section
                        Text(viewModel.userName)
                .font(.title)
                            .fontWeight(.bold)
                            .font(.headline)
                            .padding(.top)
                            

                        Text(viewModel.userEmail)
                            .font(.body)
                         

                        // Total Appliances
                        Text("Total Appliances: \(viewModel.totalAppliances)")
                            .font(.headline)
                 
                            
                Divider().background(AppColors.textColor)

                            // Current Month Title
                            Text("This Month, \(currentMonthYear())")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.primaryColor)

                            // Bill Amount Card
                            VStack {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("$\(String(format: "%.2f", viewModel1.monthlyCostAllDevices))")
                                            .font(.largeTitle)
                                            .fontWeight(.bold)
                                            .foregroundStyle(AppColors.textColor1)
                                        

                                        Text("Total Bill Amount")
                                            .font(.subheadline)
                                            .foregroundStyle(AppColors.textColor1)
                                    }
                                    Spacer()
                                    Image(systemName: "creditcard.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundStyle(AppColors.textColor1)
                                }
                                .padding()
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                            .padding(.horizontal)
                
                Divider().background(AppColors.textColor)
                NavigationLink(destination: EnergyUsageView(), isActive: $navigateToUsage) {
                    Button(action:{
                        //next page
                        navigateToUsage = true
                    }){
                        HStack(spacing: 8) { // Add spacing for better layout
                            Image(systemName: "chart.bar.fill") // Example SF Symbol
                                .foregroundColor(AppColors.primaryColor)
                            Text("Usage")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.primaryColor)
                        }
                    }
                }
                
            
                Divider().background(AppColors.textColor)
                NavigationLink(destination: PredictionView(), isActive: $navigateToPrediction) {
                    Button(action:{
                        //next page
                        
                        navigateToPrediction = true
                    }){
                        HStack(spacing: 8) { // Add spacing for better layout
                            Image(systemName: "chart.line.uptrend.xyaxis") // Example SF Symbol
                                .foregroundColor(AppColors.primaryColor)
                            Text("Usage Predictions")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.primaryColor)
                        }
                        
                    }
                }
                
                Divider().background(AppColors.textColor)
                NavigationLink(destination: AISuggestionView(), isActive: $navigateToSuggestion) {
                    Button(action:{
                        //next page
                        
                        navigateToSuggestion = true
                    }){
                        HStack(spacing: 8) { // Add spacing for better layout
                            Image(systemName: "lightbulb.fill") // Example SF Symbol
                                .foregroundColor(AppColors.primaryColor)
                            Text("AI Suggestions")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.primaryColor)
                        }
                        
                    }
                }
                Divider().background(AppColors.textColor)
                NavigationLink(destination: SettingsView(), isActive: $navigateToSettings) {
                    Button(action:{
                        navigateToSettings = true
                    }){
                        HStack(spacing: 8) { // Add spacing for better layout
                            Image(systemName: "gearshape.fill") // Example SF Symbol
                                .foregroundColor(AppColors.primaryColor)
                            Text("Settings")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.primaryColor)
                        }
                    }
                }
                Divider().background(AppColors.textColor)
                NavigationLink(destination: AboutView(), isActive: $navigateToAbout) {
                    Button(action:{
                        navigateToAbout = true
                    }){
                        HStack(spacing: 8) { // Add spacing for better layout
                            Image(systemName: "info.circle.fill") // Example SF Symbol
                                .foregroundColor(AppColors.primaryColor)
                            Text("About App")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.primaryColor)
                        }
                    }
                }
                Divider().background(AppColors.textColor)
            
               
                // Log Out Button
                Button(action: {
                    appState.isLoggedIn = false
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        print("Error signing out: \(error.localizedDescription)")
                    }
                }) {
                    HStack(spacing: 8) { // Add spacing for better layout
                        Image(systemName: "arrow.right.square") // Example SF Symbol
                            
                        Text("Log Out")
                            
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                            
                        }
                        .padding()
                    }
                }

                // Function to get current month and year
                func currentMonthYear() -> String {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "MMMM yyyy"
                    return formatter.string(from: Date())
                }
            }
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            
    }
}
