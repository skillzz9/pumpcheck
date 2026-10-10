import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

# Add viewModel to FeedPostView struct definition
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

# Pass viewModel when FeedPostView is instantiated in FeedView
old_init = """                            FeedPostView(
                                post: $post, 
                                selectedPostId: $selectedPostId,
                                onNavigateToProfile: { uid, uname in"""

new_init = """                            FeedPostView(
                                viewModel: viewModel,
                                post: $post, 
                                selectedPostId: $selectedPostId,
                                onNavigateToProfile: { uid, uname in"""

content = content.replace(old_init, new_init)

# Update toggleKudo to modify viewModel.kudos and fix Firestore writes
old_toggle = """        let db = Firestore.firestore()
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
        }"""

new_toggle = """        let db = Firestore.firestore()
        let uid = Auth.auth().currentUser?.uid ?? ""
        let postId = post.id
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if post.isKudoed {
                post.kudos -= 1
                post.isKudoed = false
                if post.userId == uid {
                    viewModel.kudos -= 1
                }
                
                if !uid.isEmpty {
                    db.collection("posts").document(postId).updateData([
                        "kudos": FieldValue.increment(Int64(-1)),
                        "kudoedBy": FieldValue.arrayRemove([uid])
                    ])
                    db.collection("users").document(post.userId).updateData([
                        "kudos": FieldValue.increment(Int64(-1))
                    ])
                }
            } else {
                post.kudos += 1
                post.isKudoed = true
                if post.userId == uid {
                    viewModel.kudos += 1
                }
                
                if !uid.isEmpty {
                    db.collection("posts").document(postId).updateData([
                        "kudos": FieldValue.increment(Int64(1)),
                        "kudoedBy": FieldValue.arrayUnion([uid])
                    ])
                    db.collection("users").document(post.userId).updateData([
                        "kudos": FieldValue.increment(Int64(1))
                    ])
                }
            }
        }"""

content = content.replace(old_toggle, new_toggle)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

