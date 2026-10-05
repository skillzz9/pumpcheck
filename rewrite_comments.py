import sys

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

# Add replyingToId state
content = content.replace('@FocusState private var isInputFocused: Bool', '@FocusState private var isInputFocused: Bool\n    @State private var replyingToId: String? = nil')

# Replace the Submit button logic
old_submit = """                Button {
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
                } label: {"""

new_submit = """                Button {
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
                        if let repId = replyingToId, let idx = post.comments.firstIndex(where: { $0.id == repId }) {
                            post.comments[idx].replies.append(newComment)
                        } else {
                            post.comments.append(newComment)
                        }
                    }
                    
                    replyingToId = nil
                    commentText = ""
                    
                    let db = Firestore.firestore()
                    let dicts = post.comments.map { c -> [String: Any] in
                        var cDict: [String: Any] = [
                            "id": c.id, "userId": c.userId, "username": c.username,
                            "photoBase64": c.photoBase64, "text": c.text, "likesCount": c.likesCount
                        ]
                        let rDicts = c.replies.map { r -> [String: Any] in
                            ["id": r.id, "userId": r.userId, "username": r.username,
                             "photoBase64": r.photoBase64, "text": r.text, "likesCount": r.likesCount]
                        }
                        cDict["replies"] = rDicts
                        return cDict
                    }
                    db.collection("posts").document(post.id).updateData(["comments": dicts])
                } label: {"""

content = content.replace(old_submit, new_submit)

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
    f.write(content)

