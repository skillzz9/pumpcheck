import sys

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

# For the post image
old_post_img = "if let data = Data(base64Encoded: post.photoBase64), let uiImage = UIImage(data: data) {"
new_post_img = "if let uiImage = ImageCache.decode(base64: post.photoBase64) {"
content = content.replace(old_post_img, new_post_img)

# For the comment pfp
old_comment_pfp = "if !comment.photoBase64.isEmpty, let imgData = Data(base64Encoded: comment.photoBase64), let uiImage = UIImage(data: imgData) {"
new_comment_pfp = "if !comment.photoBase64.isEmpty, let uiImage = ImageCache.decode(base64: comment.photoBase64) {"
content = content.replace(old_comment_pfp, new_comment_pfp)

# For the reply pfp
old_reply_pfp = "if !reply.photoBase64.isEmpty, let imgData = Data(base64Encoded: reply.photoBase64), let uiImage = UIImage(data: imgData) {"
new_reply_pfp = "if !reply.photoBase64.isEmpty, let uiImage = ImageCache.decode(base64: reply.photoBase64) {"
content = content.replace(old_reply_pfp, new_reply_pfp)

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
    f.write(content)

