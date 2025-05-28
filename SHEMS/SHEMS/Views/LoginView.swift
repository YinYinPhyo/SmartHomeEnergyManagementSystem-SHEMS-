import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = LoginViewModel()
    @State private var isSignUpPresented = false

    var body: some View {
        ZStack {
            Image("BG")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                Text("Welcome")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textColor)
                
                Text("To continue using this app, \nplease sign in first.")
                    .foregroundColor(AppColors.textColor)
                
                Image("SHEMSLogin")
                    .resizable()
                    .scaledToFit()
                
                TextField("Email", text: $viewModel.email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(AppColors.signInColor.opacity(0.8))
                   
                    .cornerRadius(10)
                    .padding(.horizontal)

                HStack {
                    if viewModel.isPasswordVisible {
                        TextField("Password", text: $viewModel.password)
                            
                           
                    } else {
                        SecureField("Password", text: $viewModel.password)
                           
                           
                    }
                    Button(action: {
                        viewModel.isPasswordVisible.toggle()
                    }) {
                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    }
                }
                .padding()
                .background(AppColors.signInColor.opacity(0.8))
                .cornerRadius(10)
                .padding(.horizontal)

                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.resetPassword()
                    }) {
                        Text("Forgot your password?")
                            .font(.footnote)
                            .foregroundColor(AppColors.textColor)
                    }
                    .padding(.trailing, 30)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Button(action: {
                    viewModel.signInUser(appState: appState)  // Pass appState directly here
                }) {
                    Text(viewModel.isLoading ? "Signing In..." : "Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.buttonColor)
                        .foregroundColor(AppColors.textColor1)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(viewModel.isLoading)

                Button(action: {
                    isSignUpPresented = true
                }) {
                    Text("Don't have an account? Sign Up now")
                        .foregroundColor(AppColors.secondaryColor)
                        .fontWeight(.bold)
                }
            }
            .padding()
        }
        .fullScreenCover(isPresented: $isSignUpPresented) {
            SignUpView(isPresented: $isSignUpPresented)
        }
    }
}
