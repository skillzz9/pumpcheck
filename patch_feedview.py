with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

target1 = """                if let selectedId = selectedPostId, let index = posts.firstIndex(where: { $0.id == selectedId }) {
                    CommentModalView(post: $posts[index], isPresented: Binding(
                        get: { selectedPostId != nil },
                        set: { if !$0 { selectedPostId = nil } }
                    ))
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
                }"""

replacement1 = """                if let selectedId = selectedPostId, let index = posts.firstIndex(where: { $0.id == selectedId }) {
                    CommentModalView(viewModel: viewModel, post: $posts[index], isPresented: Binding(
                        get: { selectedPostId != nil },
                        set: { if !$0 { selectedPostId = nil } }
                    ))
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
                }"""

if target1 in content:
    content = content.replace(target1, replacement1)
    with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
        f.write(content)
    print("Patched FeedView successfully!")
else:
    print("Target 1 not found")
