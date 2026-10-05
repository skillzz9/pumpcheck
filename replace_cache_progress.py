import sys

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "r") as f:
    content = f.read()

# For the large slider image
old_large = "if let data = Data(base64Encoded: currentEntry.photoBase64), let uiImage = UIImage(data: data) {"
new_large = "if let uiImage = ImageCache.decode(base64: currentEntry.photoBase64) {"
content = content.replace(old_large, new_large)

# For the grid images
old_grid = "if let data = Data(base64Encoded: entry.photoBase64), let uiImage = UIImage(data: data) {"
new_grid = "if let uiImage = ImageCache.decode(base64: entry.photoBase64) {"
content = content.replace(old_grid, new_grid)

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "w") as f:
    f.write(content)

