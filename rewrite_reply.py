import sys

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

old_reply = """                                        Button {
                                            commentText = "@\\(comment.username) "
                                            isInputFocused = true
                                        } label: {"""

new_reply = """                                        Button {
                                            replyingToId = comment.id
                                            commentText = "@\\(comment.username) "
                                            isInputFocused = true
                                        } label: {"""

content = content.replace(old_reply, new_reply)

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
    f.write(content)

