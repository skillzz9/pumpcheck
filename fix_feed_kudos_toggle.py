import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

old_toggle = """    private func toggleKudo() {
        #if canImport(UIKit)
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        #endif
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if post.isKudoed {
                post.kudos -= 1
            } else {
                post.kudos += 1
            }
            post.isKudoed.toggle()
        }
    }"""

new_toggle = """    private func toggleKudo() {
        #if canImport(UIKit)
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        #endif
        
        let db = Firestore.firestore()
        let uid = Auth.auth().currentUser?.uid ?? ""
        let postId = post.id
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if post.isKudoed {
                post.kudos -= 1
                post.isKudoed = false
                if !uid.isEmpty {
                    db.collection("posts").document(postId).updateData([
                        "kudos": FieldValue.increment(Int64(-1)),
                        "kudoedBy": FieldValue.arrayRemove([uid])
                    ])
                }
            } else {
                post.kudos += 1
                post.isKudoed = true
                if !uid.isEmpty {
                    db.collection("posts").document(postId).updateData([
                        "kudos": FieldValue.increment(Int64(1)),
                        "kudoedBy": FieldValue.arrayUnion([uid])
                    ])
                }
            }
        }
    }"""

content = content.replace(old_toggle, new_toggle)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

