import re

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

target_model = """struct FeedPost: Identifiable {
    let id: String
    let userId: String
    let username: String
    var profilePictureBase64: String?
    var photoBase64: String
    var photos: [String] = [] // New array for multiple photos
    var kudos: Int
    var isKudoed: Bool
    var caption: String
    var date: Date
    var comments: [PostComment] = []
}"""

# Not changing the model since it already has `var comments: [PostComment] = []`

target_fetch = """                let pfp = data["profilePictureBase64"] as? String
                let photoBase64 = data["photoBase64"] as? String ?? ""
                let photos = data["photos"] as? [String] ?? (photoBase64.isEmpty ? [] : [photoBase64])
                let caption = data["caption"] as? String ?? ""
                let kudos = data["kudos"] as? Int ?? 0
                let ts = data["date"] as? Timestamp
                let date = ts?.dateValue() ?? Date()
                
                let post = FeedPost(id: id, userId: userId, username: username, profilePictureBase64: pfp, photoBase64: photoBase64, photos: photos, kudos: kudos, isKudoed: false, caption: caption, date: date)"""

replacement_fetch = """                let pfp = data["profilePictureBase64"] as? String
                let photoBase64 = data["photoBase64"] as? String ?? ""
                let photos = data["photos"] as? [String] ?? (photoBase64.isEmpty ? [] : [photoBase64])
                let caption = data["caption"] as? String ?? ""
                let kudos = data["kudos"] as? Int ?? 0
                let ts = data["date"] as? Timestamp
                let date = ts?.dateValue() ?? Date()
                
                var parsedComments: [PostComment] = []
                if let rawComments = data["comments"] as? [[String: Any]] {
                    for c in rawComments {
                        let cId = c["id"] as? String ?? UUID().uuidString
                        let cUserId = c["userId"] as? String ?? ""
                        let cUsername = c["username"] as? String ?? ""
                        let cPhoto = c["photoBase64"] as? String ?? ""
                        let cText = c["text"] as? String ?? ""
                        let cLikes = c["likesCount"] as? Int ?? 0
                        parsedComments.append(PostComment(id: cId, userId: cUserId, username: cUsername, photoBase64: cPhoto, text: cText, isLiked: false, likesCount: cLikes))
                    }
                }
                
                var post = FeedPost(id: id, userId: userId, username: username, profilePictureBase64: pfp, photoBase64: photoBase64, photos: photos, kudos: kudos, isKudoed: false, caption: caption, date: date)
                post.comments = parsedComments"""

content = content.replace(target_fetch, replacement_fetch)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

print("Patched FeedView with comments parsing!")
