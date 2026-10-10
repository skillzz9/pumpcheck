import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var isPresented: Bool
    @Binding var isCompleted: Bool
    
    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(.top, 20)
                
                Text("Welcome Back")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                        TextField("Enter your email", text: $viewModel.email)
                            .textFieldStyle(PumpTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(Theme.textSecondary)
                        SecureField("Enter your password", text: $viewModel.password)
                            .textFieldStyle(PumpTextFieldStyle())
                    }
                }
                
                if let error = viewModel.loginErrorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        try? await viewModel.login()
                        if viewModel.loginErrorMessage == nil {
                            isPresented = false
                            withAnimation {
                                isCompleted = true
                            }
                        }
                    }
                }) {
                    if viewModel.isLoggingIn {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.paleSky))
                            .signUpButtonStyle()
                    } else {
                        Text("Login")
                            .signUpButtonStyle()
                    }
                }
                .disabled(viewModel.isLoggingIn || viewModel.email.isEmpty || viewModel.password.isEmpty)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
        }
    }
}
