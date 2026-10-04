import re

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

target = """                Button {
                    let base64 = viewModel.profileImageData?.base64EncodedString() ?? ""
                    let uid = Auth.auth().currentUser?.uid ?? ""
                    let newComment = PostComment(
                        id: UUID().uuidString,
                        userId: uid,
                        username: viewModel.username,
                        photoBase64: base64,
                        text: commentText,
                        isLiked: false,
                        likesCount: 0
                    )
                    withAnimation {
                        post.comments.append(newComment)
                    }
                    commentText = ""
                }"""

replacement = """                Button {
                    let base64 = viewModel.profileImageData?.base64EncodedString() ?? ""
                    let uid = Auth.auth().currentUser?.uid ?? ""
                    let newComment = PostComment(
                        id: UUID().uuidString,
                        userId: uid,
                        username: viewModel.username,
                        photoBase64: base64,
                        text: commentText,
                        isLiked: false,
                        likesCount: 0
                    )
                    withAnimation {
                        post.comments.append(newComment)
                    }
                    let savedText = commentText
                    commentText = ""
                    
                    let db = Firestore.firestore()
                    let commentData: [String: Any] = [
                        "id": newComment.id,
                        "userId": newComment.userId,
                        "username": newComment.username,
                        "photoBase64": newComment.photoBase64,
                        "text": savedText,
                        "likesCount": 0
                    ]
                    db.collection("posts").document(post.id).updateData([
                        "comments": FieldValue.arrayUnion([commentData])
                    ])
                }"""

content = content.replace(target, replacement)

# Add FirebaseFirestore import if not present
if "import FirebaseFirestore" not in content:
    content = content.replace("import FirebaseAuth", "import FirebaseAuth\nimport FirebaseFirestore")

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
    f.write(content)

print("Patched CommentModalView to save to Firebase!")
