import re

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

target = """            // Header
            HStack {
                Text(post.username)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)"""

replacement = """            // Header
            HStack {
                NavigationLink(destination: PublicProfileView(userId: post.userId, username: post.username)) {
                    Text(post.username)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }"""

target2 = """            // Caption
            if !post.caption.isEmpty {
                HStack(alignment: .top) {
                    Text(post.username).bold() + Text(" ") + Text(post.caption)
                }"""

replacement2 = """            // Caption
            if !post.caption.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    NavigationLink(destination: PublicProfileView(userId: post.userId, username: post.username)) {
                        Text(post.username).bold()
                            .foregroundColor(Theme.textPrimary)
                    }
                    Text(post.caption)
                        .foregroundColor(Theme.textPrimary)
                }"""

if target in content and target2 in content:
    content = content.replace(target, replacement)
    content = content.replace(target2, replacement2)
    with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
        f.write(content)
    print("Patched FeedView successfully!")
else:
    print("Target not found!")
