import re

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

target = """                                // Username and comment text
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(comment.username)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    + Text(" ")
                                    + Text(comment.text)
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.textPrimary)"""

replacement = """                                // Username and comment text
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .top, spacing: 4) {
                                        NavigationLink(destination: PublicProfileView(userId: comment.userId, username: comment.username)) {
                                            Text(comment.username)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Theme.textPrimary)
                                        }
                                        Text(comment.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(Theme.textPrimary)
                                    }"""

if target in content:
    content = content.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
        f.write(content)
    print("Patched CommentModalView successfully!")
else:
    print("Target not found!")
