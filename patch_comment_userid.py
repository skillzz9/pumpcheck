import re

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

target = """                    let newComment = PostComment(
                        id: UUID().uuidString,
                        username: viewModel.username,
                        photoBase64: base64,"""

replacement = """                    let uid = Auth.auth().currentUser?.uid ?? ""
                    let newComment = PostComment(
                        id: UUID().uuidString,
                        userId: uid,
                        username: viewModel.username,
                        photoBase64: base64,"""

if target in content:
    content = content.replace(target, replacement)
    
target2 = """import SwiftUI"""
replacement2 = """import SwiftUI
import FirebaseAuth"""
if target2 in content:
    content = content.replace(target2, replacement2, 1)

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
    f.write(content)
print("Patched CommentModalView successfully!")
