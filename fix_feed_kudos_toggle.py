import re

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

target = """        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if post.isKudoed {
                post.kudos -= 1
                post.isKudoed = false
                if !uid.isEmpty {
                    db.collection("posts").document(postId).updateData([
                        "kudos": FieldValue.increment(Int64(-1)),
                        "kudoedBy": FieldValue.arrayRemove([uid])
                    ])
                }
            } else {
                post.kudos += 1
                post.isKudoed = true
                if !uid.isEmpty {
                    db.collection("posts").document(postId).updateData([
                        "kudos": FieldValue.increment(Int64(1)),
                        "kudoedBy": FieldValue.arrayUnion([uid])
                    ])
                }
            }
        }"""

replacement = """        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if post.isKudoed {
                post.kudos -= 1
                post.isKudoed = false
                if !uid.isEmpty {
                    db.collection("posts").document(postId).setData([
                        "kudos": FieldValue.increment(Int64(-1)),
                        "kudoedBy": FieldValue.arrayRemove([uid])
                    ], merge: true)
                    
                    db.collection("users").document(post.userId).setData([
                        "kudos": FieldValue.increment(Int64(-1))
                    ], merge: true)
                }
            } else {
                post.kudos += 1
                post.isKudoed = true
                if !uid.isEmpty {
                    db.collection("posts").document(postId).setData([
                        "kudos": FieldValue.increment(Int64(1)),
                        "kudoedBy": FieldValue.arrayUnion([uid])
                    ], merge: true)
                    
                    db.collection("users").document(post.userId).setData([
                        "kudos": FieldValue.increment(Int64(1))
                    ], merge: true)
                }
            }
        }"""

content = content.replace(target, replacement)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

print("Patched toggleKudo in FeedPostView!")
