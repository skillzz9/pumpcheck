import re

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

content = content.replace("@Binding var isPresented: Bool", "var onClose: () -> Void")

content = re.sub(
    r"withAnimation\(\.spring\(response: 0\.3, dampingFraction: 0\.8\)\) \{\n\s*isPresented = false\n\s*\}",
    """onClose()""",
    content
)

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
    f.write(content)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    feed = f.read()

target = """                        isPresented: Binding(
                            get: { selectedPostId != nil },
                            set: { if !$0 { selectedPostId = nil } }
                        ),"""

replacement = """                        onClose: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedPostId = nil
                            }
                        },"""

if target in feed:
    feed = feed.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
        f.write(feed)
    print("Patched successfully!")
else:
    print("Target not found in FeedView!")
