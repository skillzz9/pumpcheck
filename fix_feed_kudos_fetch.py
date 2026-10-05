import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

old_fetch = """                let caption = data["caption"] as? String ?? ""
                let kudos = data["kudos"] as? Int ?? 0
                let ts = data["date"] as? Timestamp"""

new_fetch = """                let caption = data["caption"] as? String ?? ""
                let kudos = data["kudos"] as? Int ?? 0
                let kudoedBy = data["kudoedBy"] as? [String] ?? []
                let currentUid = Auth.auth().currentUser?.uid ?? ""
                let isKudoed = kudoedBy.contains(currentUid)
                let ts = data["date"] as? Timestamp"""

content = content.replace(old_fetch, new_fetch)

old_init = """var post = FeedPost(id: id, userId: userId, username: username, profilePictureBase64: pfp, photoBase64: photoBase64, photos: photos, kudos: kudos, isKudoed: false, caption: caption, date: date)"""

new_init = """var post = FeedPost(id: id, userId: userId, username: username, profilePictureBase64: pfp, photoBase64: photoBase64, photos: photos, kudos: kudos, isKudoed: isKudoed, caption: caption, date: date)"""

content = content.replace(old_init, new_init)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

