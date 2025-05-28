import SwiftUI

struct AboutView: View {
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (Build \(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                Text("About Smart Home Energy Management System (SHEMS)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryColor)

                Text("Our Smart Home Energy Management System (SHEMS) helps you monitor, control, and optimize your energy usage at home. Using real-time data and AI-powered recommendations, this app ensures your home stays energy-efficient and cost-effective.")
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Key Features")
                        .font(.headline)
                        .foregroundColor(.accentColor)

                    Group {
                        Text("• Monitor monthly and yearly energy usage with visual charts.")
                        Text("• Control smart devices such as lights and heaters remotely.")
                        Text("• Get AI-based predictions on future energy consumption and bills.")
                        Text("• Receive personalized energy-saving tips and alerts.")
                        Text("• Seamless integration with Raspberry Pi using MQTT protocol.")
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Our Mission")
                        .font(.headline)
                        .foregroundColor(.accentColor)

                    Text("We aim to make smart energy management accessible and simple for every home, empowering users to reduce their carbon footprint while saving on utility bills.")
                }
                
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Privacy Policy")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    
                    Text("We respect your privacy. This app may collect and use your current location to improve energy optimization based on regional weather data or usage patterns. Your location data is only used while the app is in use and is never shared with third parties.")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Terms of Use")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    
                    Text("By using this app, you agree to use the features responsibly. All data, including location and energy usage, is used to provide insights and recommendations. Misuse of the app or unauthorized access to smart devices is strictly prohibited.")
                }

                Divider()
                
                // App Version Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("App Version")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    
                    Text(appVersion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("About")
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
}
