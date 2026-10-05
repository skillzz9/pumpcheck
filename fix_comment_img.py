import re

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

target = """                Button {
                    let base64 = viewModel.profileImageData?.base64EncodedString() ?? ""
                    let uid = Auth.auth().currentUser?.uid ?? ""
                    let newComment = PostComment("""

replacement = """                Button {
                    var base64 = ""
                    if let data = viewModel.profileImageData, let uiImage = UIImage(data: data) {
                        let targetSize = CGSize(width: 80, height: 80)
                        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
                        uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
                        let resized = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        if let compressedData = resized?.jpegData(compressionQuality: 0.1) {
                            base64 = compressedData.base64EncodedString()
                        }
                    }
                    
                    let uid = Auth.auth().currentUser?.uid ?? ""
                    let newComment = PostComment("""

content = content.replace(target, replacement)

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
    f.write(content)

print("Fixed comment image compression!")
