with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

target = """struct PostComment: Identifiable {
    let id: String
    let username: String
    let photoBase64: String"""

replacement = """struct PostComment: Identifiable {
    let id: String
    let userId: String
    let username: String
    let photoBase64: String"""

if target in content:
    content = content.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
        f.write(content)
    print("Patched FeedView successfully!")
else:
    print("Target not found!")
