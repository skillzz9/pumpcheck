import SwiftUI
import FirebaseAuth

struct OnboardingWrapperView: View {
    @State private var viewModel = OnboardingViewModel()
    @State private var currentStep: Int = 1
    @State private var isCompleted: Bool = false
    @State private var isCheckingAuth: Bool = true
    @State private var showLogin: Bool = false
    
    let totalSteps = 7
    
    var body: some View {
        Group {
            if isCheckingAuth {
                ZStack {
                    Theme.bgGradient.ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                        .scaleEffect(1.5)
                }
                .onAppear {
                    checkAuthStatus()
                }
            } else if isCompleted {
                MainTabView(viewModel: viewModel)
            } else {
                ZStack {
                Theme.bgGradient.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Bar matching the thick UI inspo lines
                    ProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 32)
                    
                    // Step Content
                    TabView(selection: $currentStep) {
                        Step1View(viewModel: viewModel, onLoginTap: { showLogin = true }).tag(1)
                        Step2View(viewModel: viewModel).tag(2)
                        Step3View(viewModel: viewModel).tag(3)
                        Step4View(viewModel: viewModel).tag(4)
                        Step5View(viewModel: viewModel).tag(5)
                        Step6View(viewModel: viewModel).tag(6)
                        Step7View(viewModel: viewModel).tag(7)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    .padding(.horizontal, 20)
                    
                    // Bottom Navigation
                    HStack(spacing: 16) {
                        if currentStep > 1 {
                            Button(action: {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }) {
                                Text("Back")
                                    .pumpButtonStyle(isPrimary: false)
                            }
                            .frame(width: 100)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                        
                        Button(action: {
                            if currentStep < totalSteps {
                                withAnimation {
                                    currentStep += 1
                                }
                            } else {
                                // Final Step: Create Account
                                Task {
                                    do {
                                        try await viewModel.createAccount()
                                        withAnimation {
                                            isCompleted = true
                                        }
                                    } catch {
                                        print("Account creation failed")
                                    }
                                }
                            }
                        }) {
                            if viewModel.isCreatingAccount {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.pitchBlack))
                                    .pumpButtonStyle(isPrimary: true)
                            } else {
                                Text(currentStep == totalSteps ? "Create Account" : "Next")
                                    .pumpButtonStyle(isPrimary: true)
                            }
                        }
                        .disabled(viewModel.isCreatingAccount || (currentStep == totalSteps && (viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.password != viewModel.confirmPassword)))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            // Dismiss keyboard on tap outside
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .sheet(isPresented: $showLogin) {
                LoginView(viewModel: viewModel, isPresented: $showLogin, isCompleted: $isCompleted)
            }
        }
    }
    
    }
    func checkAuthStatus() {
        if let user = Auth.auth().currentUser {
            Task {
                do {
                    try await viewModel.fetchUserData(uid: user.uid)
                    withAnimation {
                        isCompleted = true
                        isCheckingAuth = false
                    }
                } catch {
                    withAnimation {
                        isCheckingAuth = false
                    }
                }
            }
        } else {
            withAnimation {
                isCheckingAuth = false
            }
        }
    }
}

struct ProgressBar: View {
    var currentStep: Int
    var totalSteps: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.cardBackground)
                    .frame(height: 10)
                
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 10)
                    .shadow(color: Theme.accent.opacity(0.5), radius: 6, x: 0, y: 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentStep)
            }
        }
        .frame(height: 10)
    }
}

#Preview {
    OnboardingWrapperView()
}
