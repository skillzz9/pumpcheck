import re

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

# Modify FeedPost struct
target_struct = """struct FeedPost: Identifiable {
    let id: String
    let userId: String
    let username: String
    var photoBase64: String
    var photos: [String] = [] // New array for multiple photos
    var kudos: Int"""

replacement_struct = """struct FeedPost: Identifiable {
    let id: String
    let userId: String
    let username: String
    var profilePictureBase64: String?
    var photoBase64: String
    var photos: [String] = [] // New array for multiple photos
    var kudos: Int"""

content = content.replace(target_struct, replacement_struct)

# Modify fetchPosts in FeedView
target_fetch = """                let photoBase64 = data["photoBase64"] as? String ?? ""
                let photos = data["photos"] as? [String] ?? (photoBase64.isEmpty ? [] : [photoBase64])
                let caption = data["caption"] as? String ?? ""
                let kudos = data["kudos"] as? Int ?? 0
                let ts = data["date"] as? Timestamp
                let date = ts?.dateValue() ?? Date()
                
                let post = FeedPost(id: id, userId: userId, username: username, photoBase64: photoBase64, photos: photos, kudos: kudos, isKudoed: false, caption: caption, date: date)"""

replacement_fetch = """                let pfp = data["profilePictureBase64"] as? String
                let photoBase64 = data["photoBase64"] as? String ?? ""
                let photos = data["photos"] as? [String] ?? (photoBase64.isEmpty ? [] : [photoBase64])
                let caption = data["caption"] as? String ?? ""
                let kudos = data["kudos"] as? Int ?? 0
                let ts = data["date"] as? Timestamp
                let date = ts?.dateValue() ?? Date()
                
                let post = FeedPost(id: id, userId: userId, username: username, profilePictureBase64: pfp, photoBase64: photoBase64, photos: photos, kudos: kudos, isKudoed: false, caption: caption, date: date)"""

content = content.replace(target_fetch, replacement_fetch)

# Modify FeedPostView UI (swap to left and use post.profilePictureBase64)
target_ui = """            HStack {
                Button { onNavigateToProfile(post.userId, post.username) } label: {
                    HStack(spacing: 8) {
                        Text(post.username)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            
                        if let data = profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Theme.cardBackground)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.taupeGrey)
                                )
                        }
                    }
                }"""

replacement_ui = """            HStack {
                Button { onNavigateToProfile(post.userId, post.username) } label: {
                    HStack(spacing: 12) {
                        if let pfp = post.profilePictureBase64, !pfp.isEmpty, let data = Data(base64Encoded: pfp), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Theme.cardBackground)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.taupeGrey)
                                )
                        }
                        
                        Text(post.username)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                    }
                }"""

content = content.replace(target_ui, replacement_ui)

# Remove the .task { ... } block entirely
pattern_task = r"            \.task \{.*?self\.profileImageData = imgData\n                \}\n            \}"
content = re.sub(pattern_task, "", content, flags=re.DOTALL)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "r") as f:
    create_post = f.read()

target_create = """            let postData: [String: Any] = [
                "id": postId,
                "userId": uid,
                "username": viewModel.username,
                "photoBase64": photos.first ?? "",
                "photos": photos,
                "kudos": 0,
                "caption": caption,
                "date": FieldValue.serverTimestamp()
            ]"""

replacement_create = """            var pfpStr = ""
            if let data = viewModel.profileImageData {
                pfpStr = data.base64EncodedString()
            }
            let postData: [String: Any] = [
                "id": postId,
                "userId": uid,
                "username": viewModel.username,
                "profilePictureBase64": pfpStr,
                "photoBase64": photos.first ?? "",
                "photos": photos,
                "kudos": 0,
                "caption": caption,
                "date": FieldValue.serverTimestamp()
            ]"""

create_post = create_post.replace(target_create, replacement_create)
with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "w") as f:
    f.write(create_post)

print("Patched FeedView to use embedded PFP on left!")
