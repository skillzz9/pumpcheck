import re

with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "r") as f:
    content = f.read()

target_state = """struct ProgramView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var isSignedUp = false
    @State private var isUpdating = false"""

replacement_state = """struct ProgramView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var isSignedUp = false
    @State private var isUpdating = false
    @State private var isCheckingStatus = true"""

content = content.replace(target_state, replacement_state)

target_button = """                            HStack(spacing: 8) {
                                if isUpdating {
                                    ProgressView().tint(Theme.pitchBlack)
                                } else if isSignedUp {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Signed Up!")
                                } else {
                                    Text("Sign Up for Early Access")
                                }
                            }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.pitchBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isSignedUp ? Color.green : Theme.accent)
                            .cornerRadius(16)
                            .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isSignedUp || isUpdating)"""

replacement_button = """                            HStack(spacing: 8) {
                                if isCheckingStatus || isUpdating {
                                    ProgressView().tint(Theme.pitchBlack)
                                } else if isSignedUp {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Signed Up!")
                                } else {
                                    Text("Sign Up for Early Access")
                                }
                            }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.pitchBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background((isSignedUp && !isCheckingStatus) ? Color.green : Theme.accent)
                            .cornerRadius(16)
                            .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isSignedUp || isUpdating || isCheckingStatus)"""

content = content.replace(target_button, replacement_button)

target_func = """    private func checkSignUpStatus() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { doc, _ in
            if let data = doc?.data(), let signedUp = data["programSignUp"] as? Bool {
                self.isSignedUp = signedUp
            }
        }
    }"""

replacement_func = """    private func checkSignUpStatus() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.isCheckingStatus = false
            return 
        }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { doc, _ in
            if let data = doc?.data(), let signedUp = data["programSignUp"] as? Bool {
                self.isSignedUp = signedUp
            }
            withAnimation {
                self.isCheckingStatus = false
            }
        }
    }"""

content = content.replace(target_func, replacement_func)

with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "w") as f:
    f.write(content)

print("Patched ProgramView to handle initial loading state!")
