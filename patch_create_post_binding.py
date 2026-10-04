import re

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "r") as f:
    content = f.read()

content = content.replace(
"""struct CreatePostModalView: View {
    @Bindable var viewModel: OnboardingViewModel
    var onPostCreated: () -> Void
    @Environment(\\.dismiss) var dismiss""",
"""struct CreatePostModalView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var isPresented: Bool
    var onPostCreated: () -> Void
    @Environment(\\.dismiss) var dismiss""")

content = content.replace(
"""                await MainActor.run {
                    isUploading = false
                    onPostCreated()
                    dismiss()
                }""",
"""                await MainActor.run {
                    isUploading = false
                    onPostCreated()
                    isPresented = false
                    dismiss()
                }""")

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "w") as f:
    f.write(content)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    feed = f.read()

feed = feed.replace(
"""            CreatePostModalView(viewModel: viewModel, onPostCreated: {""",
"""            CreatePostModalView(viewModel: viewModel, isPresented: $showCreatePost, onPostCreated: {""")

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(feed)

print("Patched isPresented binding!")
