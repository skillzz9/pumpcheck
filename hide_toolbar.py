import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

old_toolbar = """            }
        }
        .task {"""

new_toolbar = """            }
            .toolbar(selectedPostId == nil ? .visible : .hidden, for: .navigationBar)
        }
        .task {"""

content = content.replace(old_toolbar, new_toolbar)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

