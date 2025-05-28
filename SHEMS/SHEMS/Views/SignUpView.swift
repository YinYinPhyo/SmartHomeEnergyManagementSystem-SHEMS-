import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Image("BG")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 15) {
                Text("Create Your Account")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.textColor)

                Image("SHEMSSignUp")
                    .resizable()
                    .scaledToFit()
                
                TextField("Full Name", text: $viewModel.name)
                    .autocapitalization(.none)
                    .padding()
                    .background(AppColors.signInColor.opacity(0.8))
                    .background(AppColors.signInColor.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.horizontal)

                TextField("Email", text: $viewModel.email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(AppColors.signInColor.opacity(0.8))
                   
                    .cornerRadius(10)
                    .padding(.horizontal)

                HStack {
                    if viewModel.isPasswordVisible {
                        TextField("Create Password", text: $viewModel.password)
                            .foregroundColor(AppColors.textColor1)
                    } else {
                        SecureField("Create Password", text: $viewModel.password)
                            .foregroundColor(AppColors.textColor1)
                    }
                    Button(action: { viewModel.isPasswordVisible.toggle() }) {
                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    }
                }
                .padding()
                .background(AppColors.signInColor.opacity(0.8))
                .cornerRadius(10)
                .padding(.horizontal)

                HStack {
                    if viewModel.isConfirmPasswordVisible {
                        TextField("Re-type Password", text: $viewModel.confirmPassword)
                    } else {
                        SecureField("Re-type Password", text: $viewModel.confirmPassword)
                    }
                    Button(action: { viewModel.isConfirmPasswordVisible.toggle() }) {
                        Image(systemName: viewModel.isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    }
                }
                .padding()
                .background(AppColors.signInColor.opacity(0.8))
                .cornerRadius(10)
                .padding(.horizontal)

                Button(action: viewModel.registerUser) {
                    Text("Create Your Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.buttonColor)
                        .foregroundColor(AppColors.textColor1)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Button(action: {
                    isPresented = false
                }) {
                    Text("Already have an account? Sign In now")
                        .foregroundColor(AppColors.secondaryColor)
                        .fontWeight(.bold)
                }
            }
            .padding()
        }
        .alert(isPresented: $viewModel.showVerificationAlert) {
            Alert(
                title: Text("Verification Email Sent"),
                message: Text("We sent a verification email to your email address. Please verify it before logging in."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

