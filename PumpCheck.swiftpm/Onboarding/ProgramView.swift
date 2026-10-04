import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProgramView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var isSignedUp = false
    @State private var isUpdating = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.pitchBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        
                        // Hero Images Section
                        HStack(spacing: 20) {
                            // User Profile Picture
                            VStack(spacing: 12) {
                                if let data = viewModel.profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                                } else {
                                    Circle()
                                        .fill(Theme.cardBackground)
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(Theme.taupeGrey)
                                        )
                                }
                                
                                Text("Current You")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            
                            // Arrow
                            Image(systemName: "arrow.right")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Theme.accent)
                                .padding(.bottom, 30) // align with circles
                            
                            // Dream Physique
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.cardBackground)
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Circle().stroke(Theme.accent, style: StrokeStyle(lineWidth: 2, dash: [6]))
                                        )
                                    
                                    Image(systemName: "questionmark")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(Theme.accent)
                                }
                                
                                Text("Dream Physique")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.accent)
                            }
                        }
                        .padding(.top, 40)
                        
                        // Value Propositions
                        VStack(alignment: .leading, spacing: 24) {
                            FeatureRow(
                                icon: "brain.head.profile",
                                title: "AI Analysis",
                                description: "Analysis on what is different between you and your dream physique and creates a custom workout program just for you."
                            )
                            
                            FeatureRow(
                                icon: "camera.filters",
                                title: "Dynamic Adaptation",
                                description: "Changes based on your progress pictures, sees what is going well and what is not."
                            )
                            
                            FeatureRow(
                                icon: "fork.knife",
                                title: "Custom Diet",
                                description: "Custom diet depending on your goals."
                            )
                            
                            FeatureRow(
                                icon: "checkmark.seal.fill",
                                title: "Guaranteed Results",
                                description: "Know that your workout is pushing you to your dream physique."
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // CTA Button
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
                        .disabled(isSignedUp || isUpdating)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Program")
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
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardBackground)
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Theme.textSecondary)
                    .lineSpacing(2)
            }
        }
    }
}
