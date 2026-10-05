import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

old_btn = """                    Button(action: { showCreatePost = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.accent)
                    }"""

new_btn = """                    Button(action: { showCreatePost = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.accent)
                    }
                    .buttonStyle(.plain)"""

content = content.replace(old_btn, new_btn)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

