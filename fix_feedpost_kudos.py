import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

# 1. Update FeedPostView initialization in FeedView
old_init = """                            FeedPostView(
                                post: $post, 
                                selectedPostId: $selectedPostId,"""

new_init = """                            FeedPostView(
                                viewModel: viewModel,
                                post: $post, 
                                selectedPostId: $selectedPostId,"""

content = content.replace(old_init, new_init)

# 2. Add viewModel to FeedPostView struct
old_struct = """struct FeedPostView: View {
    @Binding var post: FeedPost
    @Binding var selectedPostId: String?
    var onNavigateToProfile: (String, String) -> Void"""

new_struct = """struct FeedPostView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var post: FeedPost
    @Binding var selectedPostId: String?
    var onNavigateToProfile: (String, String) -> Void"""

content = content.replace(old_struct, new_struct)

# 3. Update toggleKudo logic to update viewModel.kudos and fix Firebase updates
old_toggle = """    private func toggleKudo() {
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
                    db.collection("posts").document(postId).setData([
                        "kudos": FieldValue.increment(Int64(-1)),
                        "kudoedBy": FieldValue.arrayRemove([uid])
                    ], merge: true)
                    
                    db.collection("users").document(post.userId).setData([
                        "kudos": FieldValue.increment(Int64(-1))
                    ], merge: true)
                }
            } else {
                post.kudos += 1
                post.isKudoed = true
                if !uid.isEmpty {
                    db.collection("posts").document(postId).setData([
                        "kudos": FieldValue.increment(Int64(1)),
                        "kudoedBy": FieldValue.arrayUnion([uid])
                    ], merge: true)
                    
                    db.collection("users").document(post.userId).setData([
                        "kudos": FieldValue.increment(Int64(1))
                    ], merge: true)
                }
            }
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
        let postUserId = post.userId
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if post.isKudoed {
                post.kudos -= 1
                post.isKudoed = false
                
                if postUserId == uid {
                    viewModel.kudos -= 1
                }
                
                if !uid.isEmpty {
                    db.collection("posts").document(postId).updateData([
                        "kudos": FieldValue.increment(Int64(-1)),
                        "kudoedBy": FieldValue.arrayRemove([uid])
                    ])
                    
                    db.collection("users").document(postUserId).updateData([
                        "kudos": FieldValue.increment(Int64(-1))
                    ])
                }
            } else {
                post.kudos += 1
                post.isKudoed = true
                
                if postUserId == uid {
                    viewModel.kudos += 1
                }
                
                if !uid.isEmpty {
                    db.collection("posts").document(postId).updateData([
                        "kudos": FieldValue.increment(Int64(1)),
                        "kudoedBy": FieldValue.arrayUnion([uid])
                    ])
                    
                    db.collection("users").document(postUserId).updateData([
                        "kudos": FieldValue.increment(Int64(1))
                    ])
                }
            }
        }
    }"""

content = content.replace(old_toggle, new_toggle)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

