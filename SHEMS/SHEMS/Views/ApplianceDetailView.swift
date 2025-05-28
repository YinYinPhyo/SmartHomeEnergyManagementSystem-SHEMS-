import SwiftUI
import Charts

struct ApplianceDetailView: View {
    @StateObject private var viewModel = ApplianceDetailViewModel()
    let deviceId: String
    
    var body: some View {
        ZStack {
            Image("BG")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else if let device = viewModel.device {
                    Text(device.device.name)
                        .font(.custom("TrebuchetMS-Bold", size: 22))
                        .foregroundStyle(AppColors.primaryColor)
                        .padding(.top)

                    HStack {
                        Image(device.device.image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .padding()
                        
                        if let energyData = device.energyData {
                            Toggle("Power", isOn: Binding(
                                get: { energyData.isOn },
                                set: { newValue in
                                    if let deviceId = device.device.id {
                                        viewModel.updateDevicePowerState(deviceId: deviceId, isOn: newValue)
                                        viewModel.device?.energyData?.isOn = newValue
                                    }
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: AppColors.secondaryColor))
                            .padding(.top, 5)
                        } else {
                            Text("Energy data not available")
                                .foregroundColor(.red)
                        }
                    }

                    EnergyUsageCard(energyData: device.energyData)
                    
                    // Pass rate into BillAmountCard
                    BillAmountCard(energyData: device.energyData, rate: viewModel.userRate)
                    
                    Spacer()
                } else {
                    Text("Error: Device data not found.")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
            .navigationTitle("Device Details")
        }
        .onAppear {
            viewModel.fetchDevice(deviceId: deviceId)
            viewModel.fetchUserRate()
        }
    }
}

struct EnergyUsageCard: View {
    let energyData: EnergyData?

    var body: some View {
        VStack {
            Text("Today's Usage")
                .font(.custom("TrebuchetMS-Bold", size: 20))
                .foregroundStyle(AppColors.primaryColor)
                .padding(.top)
            
            HStack {
                VStack {
                    Text("Time Used")
                        .foregroundStyle(AppColors.textColor1)
                    let hours = (energyData?.usageTime ?? 0) / 60
                    let minutes = (energyData?.usageTime ?? 0) % 60
                    Text("\(hours) H \(minutes) M")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.textColor1)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 100)
                    .background(AppColors.secondaryColor)
                
                VStack {
                    Text("Energy Consumption")
                        .foregroundStyle(AppColors.textColor1)
                    Text("\(energyData?.consumption ?? 0, specifier: "%.2f") kWh")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.textColor1)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

struct BillAmountCard: View {
    let energyData: EnergyData?
    let rate: Double?

    var body: some View {
        VStack {
            Text("Electricity Cost")
                .font(.custom("TrebuchetMS-Bold", size: 20))
                .foregroundStyle(AppColors.primaryColor)
                .padding(.top)
            
            HStack {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(AppColors.secondaryColor)
                    VStack {
                        Text("Estimated Bill: ")
                        Text("$\(String(format: "%.2f", energyData?.cost ?? 0))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.textColor1)
                    }
                }
                .padding()
                Spacer()

                Image("Bill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            }
            .padding(.horizontal)
            
            if let rate = rate {
                Text("Rate: \(rate, specifier: "%.2f") $/kWh")
                    .foregroundStyle(AppColors.textColor1)
                    .padding(.bottom)
            } else {
                Text("Loading rate...")
                    .foregroundStyle(AppColors.textColor1)
                    .padding(.bottom)
            }

        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}
