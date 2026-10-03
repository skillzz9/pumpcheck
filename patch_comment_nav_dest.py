import re

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

content = content.replace("@Binding var isPresented: Bool", "@Binding var isPresented: Bool\n    var onNavigateToProfile: (String, String) -> Void")

content = re.sub(
    r"NavigationLink\(destination: PublicProfileView\(userId: comment\.userId, username: comment\.username\)\) \{\n(.*?)Text\(comment\.username\)\n(.*?).font\(\.system\(size: 14, weight: \.bold\)\)\n(.*?).foregroundColor\(Theme\.textPrimary\)\n(.*?)\}",
    """Button { onNavigateToProfile(comment.userId, comment.username) } label: {\n\\1Text(comment.username)\n\\2.font(.system(size: 14, weight: .bold))\n\\3.foregroundColor(Theme.textPrimary)\n\\4}""",
    content
)

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
    f.write(content)

print("Patched CommentModalView successfully!")
