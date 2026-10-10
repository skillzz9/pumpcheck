import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

old_change = """        }
        .task {
            if posts.isEmpty {
                await fetchPosts()
            }
        }"""

new_change = """        }
        .task {
            if posts.isEmpty {
                await fetchPosts()
            }
        }
        .onChange(of: viewModel.blockedUsers) { _, blocked in
            posts.removeAll(where: { blocked.contains($0.userId) })
        }"""

content = content.replace(old_change, new_change)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

