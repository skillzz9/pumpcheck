import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

old_menu = """                Spacer()
                Text(post.date, style: .time)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 16)"""

new_menu = """                Spacer()
                Text(post.date, style: .time)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                
                Menu {
                    Button(role: .destructive) {
                        let db = Firestore.firestore()
                        let uid = Auth.auth().currentUser?.uid ?? ""
                        db.collection("reports").addDocument(data: [
                            "postId": post.id,
                            "reporterId": uid,
                            "postUserId": post.userId,
                            "reason": "Inappropriate Content",
                            "date": FieldValue.serverTimestamp()
                        ])
                    } label: {
                        Label("Report Post", systemImage: "exclamationmark.bubble")
                    }
                    
                    Button(role: .destructive) {
                        let db = Firestore.firestore()
                        let uid = Auth.auth().currentUser?.uid ?? ""
                        if !uid.isEmpty {
                            db.collection("users").document(uid).updateData([
                                "blockedUsers": FieldValue.arrayUnion([post.userId])
                            ])
                            viewModel.blockedUsers.append(post.userId)
                        }
                    } label: {
                        Label("Block User", systemImage: "person.fill.xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(Theme.textSecondary)
                        .padding(.leading, 8)
                }
            }
            .padding(.horizontal, 16)"""

content = content.replace(old_menu, new_menu)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

