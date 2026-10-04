import re

with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "r") as f:
    content = f.read()

# 1. Add state variable and import Firestore
content = content.replace("import SwiftUI\n", "import SwiftUI\nimport FirebaseFirestore\nimport FirebaseAuth\n")

target_struct = """struct ProgramView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {"""

replacement_struct = """struct ProgramView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var isSignedUp = false
    @State private var isUpdating = false
    
    var body: some View {"""

content = content.replace(target_struct, replacement_struct)

# 2. Update the button
target_button = """                        // CTA Button
                        Button {
                            // Action coming soon
                        } label: {
                            Text("Generate Custom Program")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.pitchBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.accent)
                                .cornerRadius(16)
                                .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                        }"""

replacement_button = """                        // CTA Button
                        Button {
                            if !isSignedUp && !isUpdating {
                                signUpForEarlyAccess()
                            }
                        } label: {
                            HStack(spacing: 8) {
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

content = content.replace(target_button, replacement_button)

# 3. Add the task modifier and function
target_end = """            .navigationTitle("Program")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}"""

replacement_end = """            .navigationTitle("Program")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                checkSignUpStatus()
            }
        }
    }
    
    private func checkSignUpStatus() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { doc, _ in
            if let data = doc?.data(), let signedUp = data["programSignUp"] as? Bool {
                self.isSignedUp = signedUp
            }
        }
    }
    
    private func signUpForEarlyAccess() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isUpdating = true
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "programSignUp": true
        ]) { error in
            isUpdating = false
            if error == nil {
                withAnimation {
                    isSignedUp = true
                }
            } else {
                // If it fails because the document doesn't have the field yet and rules prevent update? 
                // Actually updateData works fine, but we can fallback to setData(merge:true)
                db.collection("users").document(uid).setData(["programSignUp": true], merge: true) { _ in
                    withAnimation {
                        isSignedUp = true
                    }
                }
            }
        }
    }
}"""

content = content.replace(target_end, replacement_end)

with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "w") as f:
    f.write(content)

print("Patched ProgramView successfully!")
