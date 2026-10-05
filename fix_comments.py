import re

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

target_save = """                    let db = Firestore.firestore()
                    let dicts = post.comments.map { c -> [String: Any] in
                        var cDict: [String: Any] = [
                            "id": c.id, "userId": c.userId, "username": c.username,
                            "photoBase64": c.photoBase64, "text": c.text, "likesCount": c.likesCount
                        ]
                        let rDicts = c.replies.map { r -> [String: Any] in
                            ["id": r.id, "userId": r.userId, "username": r.username,
                             "photoBase64": r.photoBase64, "text": r.text, "likesCount": r.likesCount]
                        }
                        cDict["replies"] = rDicts
                        return cDict
                    }
                    db.collection("posts").document(post.id).updateData(["comments": dicts])"""

replacement_save = """                    let db = Firestore.firestore()
                    let dicts = post.comments.map { c -> [String: Any] in
                        var cDict: [String: Any] = [
                            "id": c.id, "userId": c.userId, "username": c.username,
                            "photoBase64": c.photoBase64, "text": c.text, "likesCount": c.likesCount
                        ]
                        let rDicts = c.replies.map { r -> [String: Any] in
                            ["id": r.id, "userId": r.userId, "username": r.username,
                             "photoBase64": r.photoBase64, "text": r.text, "likesCount": r.likesCount]
                        }
                        cDict["replies"] = rDicts
                        return cDict
                    }
                    db.collection("posts").document(post.id).setData(["comments": dicts], merge: true) { error in
                        if let error = error {
                            print("Firebase Comment Save Error: \\(error.localizedDescription)")
                            // Fallback to updating the whole post just in case the post was deleted?
                        }
                    }"""

content = content.replace(target_save, replacement_save)

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
    f.write(content)

# Now fix FeedView to use fullScreenCover
with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    feed = f.read()

target_zstack_comment = """                if let selectedId = selectedPostId, let index = posts.firstIndex(where: { $0.id == selectedId }) {
                    CommentModalView(
                        viewModel: viewModel, 
                        post: $posts[index], 
                        onClose: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedPostId = nil
                            }
                        },
                        onNavigateToProfile: { uid, uname in
                            selectedPostId = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navToProfileId = uid
                                navToProfileName = uname
                            }
                        }
                    )
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
                }
            }
            .navigationTitle("Feed")"""

replacement_zstack_comment = """            }
            .navigationTitle("Feed")"""

feed = feed.replace(target_zstack_comment, replacement_zstack_comment)

target_sheet = """        .sheet(isPresented: $showCreatePost) {
            CreatePostModalView(viewModel: viewModel, isPresented: $showCreatePost, onPostCreated: {
                Task {
                    await fetchPosts()
                }
            })
        }"""

replacement_sheet = """        .sheet(isPresented: $showCreatePost) {
            CreatePostModalView(viewModel: viewModel, isPresented: $showCreatePost, onPostCreated: {
                Task {
                    await fetchPosts()
                }
            })
        }
        .fullScreenCover(isPresented: Binding(
            get: { selectedPostId != nil },
            set: { if !$0 { selectedPostId = nil } }
        )) {
            if let selectedId = selectedPostId, let index = posts.firstIndex(where: { $0.id == selectedId }) {
                CommentModalView(
                    viewModel: viewModel, 
                    post: $posts[index], 
                    onClose: {
                        selectedPostId = nil
                    },
                    onNavigateToProfile: { uid, uname in
                        selectedPostId = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            navToProfileId = uid
                            navToProfileName = uname
                        }
                    }
                )
            }
        }"""

feed = feed.replace(target_sheet, replacement_sheet)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(feed)

print("Fixed comments saving and overlay!")
