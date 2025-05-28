import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LandingView: View {
    @StateObject private var viewModel = LandingViewModel()
    @State private var selectedFilter: String = "all"
    @EnvironmentObject var appState: AppState
    @State private var navigateToHome = false

    var body: some View {
        NavigationView {
            ZStack {
                Image("BG")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Welcome home,\n\(viewModel.userName)!")
                            .font(.custom("NotoSansOriya-Bold", size: 22))
                            .foregroundColor(AppColors.primaryColor)
                            .padding(.top)

                        Spacer()

                        NavigationLink(destination: HomeView(), isActive: $navigateToHome) {
                            Button(action: {
                                navigateToHome = true
                            }) {
                                Image(systemName: "house.fill")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(AppColors.primaryColor)
                                    .padding()
                                    .background(Circle().fill(Color.white).shadow(radius: 4))
                            }
                        }
                    }
                    .padding()

                    Text("Filter By:")
                        .font(.custom("Montaga-Regular", size: 20))
                        .padding(.horizontal)

                    Picker("Filter By", selection: $selectedFilter) {
                        Text("All").tag("all")
                        Text("Light").tag("light")
                        Text("Heater").tag("heater")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    Text("Appliances")
                        .font(.custom("Montaga-Regular", size: 20))
                        .padding(.horizontal)

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.devices.filter {
                                selectedFilter == "all" || $0.device.category == selectedFilter
                            }, id: \.id) { deviceWithEnergy in
                                DeviceCardView(deviceWithEnergy: Binding(
                                    get: {
                                        if let index = viewModel.devices.firstIndex(where: { $0.id == deviceWithEnergy.id }) {
                                            return viewModel.devices[index]
                                        } else {
                                            return deviceWithEnergy
                                        }
                                    },
                                    set: { newValue in
                                        if let index = viewModel.devices.firstIndex(where: { $0.id == newValue.id }) {
                                            viewModel.devices[index] = newValue
                                        }
                                    }
                                ))
                            }
                        }
                        .padding(.top)
                    }

                    Spacer()
                }
                .navigationBarHidden(true)
            }
            .onAppear {
                viewModel.fetchUserData()
            }
            .onDisappear {
                viewModel.stopListening()
            }
        }
    }
}
