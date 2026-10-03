with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

target1 = """struct CommentModalView: View {
    @Binding var post: FeedPost
    @Binding var isPresented: Bool"""

replacement1 = """struct CommentModalView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var post: FeedPost
    @Binding var isPresented: Bool"""

target2 = """                                // Profile picture mock
                                Circle()
                                    .fill(Theme.taupeGrey.opacity(0.5))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Text(String(comment.username.prefix(1).uppercased()))
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                    )"""

replacement2 = """                                // Profile picture
                                Group {
                                    if !comment.photoBase64.isEmpty, let imgData = Data(base64Encoded: comment.photoBase64), let uiImage = UIImage(data: imgData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 36, height: 36)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Theme.taupeGrey.opacity(0.5))
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Text(String(comment.username.prefix(1).uppercased()))
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(Theme.textPrimary)
                                            )
                                    }
                                }"""

target3 = """                Button {
                    let newComment = PostComment(
                        id: UUID().uuidString,
                        username: "me", // Current user mock
                        text: commentText,"""

replacement3 = """                Button {
                    let base64 = viewModel.profileImageData?.base64EncodedString() ?? ""
                    let newComment = PostComment(
                        id: UUID().uuidString,
                        username: viewModel.username,
                        photoBase64: base64,
                        text: commentText,"""

if target1 in content and target2 in content and target3 in content:
    content = content.replace(target1, replacement1)
    content = content.replace(target2, replacement2)
    content = content.replace(target3, replacement3)
    with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
        f.write(content)
    print("Patched CommentModalView successfully!")
else:
    if target1 not in content: print("Target 1 not found")
    if target2 not in content: print("Target 2 not found")
    if target3 not in content: print("Target 3 not found")
