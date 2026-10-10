import sys

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content = f.read()

old_scroll = "            ScrollView {"
new_scroll = """            ScrollView {
                HStack {
                    Spacer()
                    Menu {
                        Button(role: .destructive, action: {
                            Task {
                                guard let uid = Auth.auth().currentUser?.uid else { return }
                                let db = Firestore.firestore()
                                // Delete user document
                                try? await db.collection("users").document(uid).delete()
                                // Note: A cloud function should ideally delete posts/comments, but we delete auth here
                                try? await Auth.auth().currentUser?.delete()
                                try? Auth.auth().signOut()
                                viewModel.reset()
                            }
                        }) {
                            Label("Delete Account", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.textSecondary)
                            .padding()
                    }
                }"""

content = content.replace(old_scroll, new_scroll)

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
    f.write(content)

