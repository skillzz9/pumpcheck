import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

old_comment_btn = """                // Comment Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedPostId = post.id
                    }
                } label: {
                    Image(systemName: "message")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.textPrimary)
                }"""

new_comment_btn = """                // Comment Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedPostId = post.id
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "message")
                            .font(.system(size: 24))
                        
                        let totalComments = post.comments.reduce(0) { $0 + 1 + $1.replies.count }
                        if totalComments > 0 {
                            Text("\\(totalComments)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                    }
                    .foregroundColor(Theme.textPrimary)
                }"""

content = content.replace(old_comment_btn, new_comment_btn)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

