import re

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "r") as f:
    content = f.read()

target = """            var pfpStr = ""
            if let data = viewModel.profileImageData {
                pfpStr = data.base64EncodedString()
            }"""

replacement = """            var pfpStr = ""
            if let data = viewModel.profileImageData, let uiImage = UIImage(data: data) {
                let targetSize = CGSize(width: 100, height: 100)
                UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
                uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
                let resized = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                if let compressedData = resized?.jpegData(compressionQuality: 0.2) {
                    pfpStr = compressedData.base64EncodedString()
                }
            }"""

content = content.replace(target, replacement)

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "w") as f:
    f.write(content)

print("Fixed post profile picture compression!")
