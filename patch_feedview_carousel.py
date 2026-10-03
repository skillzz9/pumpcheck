import re

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

target_model = """struct FeedPost: Identifiable {
    let id: String
    let userId: String
    let username: String
    var photoBase64: String
    var kudos: Int"""

replacement_model = """struct FeedPost: Identifiable {
    let id: String
    let userId: String
    let username: String
    var photoBase64: String
    var photos: [String] = [] // New array for multiple photos
    var kudos: Int"""
content = content.replace(target_model, replacement_model)

target_fetch = """                let photoBase64 = data["photoBase64"] as? String ?? ""
                let caption = data["caption"] as? String ?? ""
                let kudos = data["kudos"] as? Int ?? 0
                let ts = data["date"] as? Timestamp
                let date = ts?.dateValue() ?? Date()
                
                let post = FeedPost(id: id, userId: userId, username: username, photoBase64: photoBase64, kudos: kudos, isKudoed: false, caption: caption, date: date)"""

replacement_fetch = """                let photoBase64 = data["photoBase64"] as? String ?? ""
                let photos = data["photos"] as? [String] ?? (photoBase64.isEmpty ? [] : [photoBase64])
                let caption = data["caption"] as? String ?? ""
                let kudos = data["kudos"] as? Int ?? 0
                let ts = data["date"] as? Timestamp
                let date = ts?.dateValue() ?? Date()
                
                let post = FeedPost(id: id, userId: userId, username: username, photoBase64: photoBase64, photos: photos, kudos: kudos, isKudoed: false, caption: caption, date: date)"""
content = content.replace(target_fetch, replacement_fetch)

target_image_area = """            // Image area
            if let data = Data(base64Encoded: post.photoBase64), let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.0, contentMode: .fit)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Theme.cardBackground)
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.taupeGrey.opacity(0.5))
                    }
            }"""

replacement_image_area = """            // Image area
            if post.photos.count > 1 {
                TabView {
                    ForEach(post.photos.indices, id: \\.self) { idx in
                        if let data = Data(base64Encoded: post.photos[idx]), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .aspectRatio(1.0, contentMode: .fit)
                .clipped()
            } else if let firstPhoto = post.photos.first, let data = Data(base64Encoded: firstPhoto), let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.0, contentMode: .fit)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Theme.cardBackground)
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.taupeGrey.opacity(0.5))
                    }
            }"""
content = content.replace(target_image_area, replacement_image_area)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

print("Patched FeedView with Carousel support!")
