import re

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "r") as f:
    content = f.read()

content = content.replace(
"""struct CreatePostModalView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\\.dismiss) var dismiss""",
"""struct CreatePostModalView: View {
    @Bindable var viewModel: OnboardingViewModel
    var onPostCreated: () -> Void
    @Environment(\\.dismiss) var dismiss""")

content = content.replace(
"""        db.collection("posts").document(postId).setData(postData) { error in
            isUploading = false
            if error == nil {
                dismiss()
            }
        }""",
"""        db.collection("posts").document(postId).setData(postData) { error in
            isUploading = false
            if error == nil {
                onPostCreated()
                dismiss()
            }
        }""")

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "w") as f:
    f.write(content)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    feed = f.read()

feed = feed.replace(
"""            CreatePostModalView(isPresented: $showCreatePost, viewModel: viewModel, onPostCreated: {""",
"""            CreatePostModalView(viewModel: viewModel, onPostCreated: {""")

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(feed)

print("Fixed CreatePostModalView arguments!")
