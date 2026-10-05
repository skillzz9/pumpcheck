import re

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

target = """                var post = FeedPost(id: id, userId: userId, username: username, profilePictureBase64: pfp, photoBase64: photoBase64, photos: photos, kudos: kudos, isKudoed: false, caption: caption, date: date)"""
replacement = """                var post = FeedPost(id: id, userId: userId, username: username, profilePictureBase64: pfp, photoBase64: photoBase64, photos: photos, kudos: kudos, isKudoed: isKudoed, caption: caption, date: date)"""

content = content.replace(target, replacement)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

print("Patched isKudoed in FeedView fetchPosts!")
