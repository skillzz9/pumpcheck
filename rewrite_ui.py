import sys

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

old_loop = """                        ForEach($post.comments) { $comment in
                            HStack(alignment: .top, spacing: 12) {"""

new_loop = """                        ForEach($post.comments) { $comment in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {"""

content = content.replace(old_loop, new_loop)


# Now we need to append the replies loop right after the root comment's HStack closes.
# The root comment's HStack closes right before `                        }` which is followed by `                    }` for LazyVStack maybe?
# Let's find the closing brace of HStack.
old_close = """                                }
                                .padding(.top, 2)
                            }"""

new_close = """                                }
                                .padding(.top, 2)
                            }
                            
                            if !comment.replies.isEmpty {
                                ForEach($comment.replies) { $reply in
                                    HStack(alignment: .top, spacing: 12) {
                                        Group {
                                            if !reply.photoBase64.isEmpty, let imgData = Data(base64Encoded: reply.photoBase64), let uiImage = UIImage(data: imgData) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 28, height: 28)
                                                    .clipShape(Circle())
                                            } else {
                                                Circle()
                                                    .fill(Theme.taupeGrey.opacity(0.5))
                                                    .frame(width: 28, height: 28)
                                                    .overlay(
                                                        Text(String(reply.username.prefix(1).uppercased()))
                                                            .font(.system(size: 12, weight: .bold))
                                                            .foregroundColor(Theme.textPrimary)
                                                    )
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(alignment: .top, spacing: 4) {
                                                Button { onNavigateToProfile(reply.userId, reply.username) } label: {
                                                    Text(reply.username)
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(Theme.textPrimary)
                                                }
                                                Text(reply.text)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(Theme.textPrimary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            withAnimation {
                                                if reply.isLiked {
                                                    reply.likesCount -= 1
                                                } else {
                                                    reply.likesCount += 1
                                                }
                                                reply.isLiked.toggle()
                                            }
                                        } label: {
                                            Image(systemName: reply.isLiked ? "heart.fill" : "heart")
                                                .font(.system(size: 12))
                                                .foregroundColor(reply.isLiked ? Theme.accent : Theme.textSecondary)
                                        }
                                        .padding(.top, 2)
                                    }
                                    .padding(.leading, 48)
                                }
                            }
                        }"""

content = content.replace(old_close, new_close)

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
    f.write(content)

