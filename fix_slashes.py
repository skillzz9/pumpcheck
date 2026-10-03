import re

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "r") as f:
    content = f.read()

content = content.replace(r"\\", "\\")

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "w") as f:
    f.write(content)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    feed = f.read()

feed = feed.replace(r"\\", "\\")

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(feed)

print("Fixed backslashes!")
