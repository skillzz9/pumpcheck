import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

# For the post multiple photos
old_slider = """                       let data = Data(base64Encoded: post.photos[currentIndex]),
                       let uiImage = UIImage(data: data) {"""
new_slider = """                       let uiImage = ImageCache.decode(base64: post.photos[currentIndex]) {"""
content = content.replace(old_slider, new_slider)

# For the single photo fallback
old_single = """            } else if let firstPhoto = post.photos.first, let data = Data(base64Encoded: firstPhoto), let uiImage = UIImage(data: data) {"""
new_single = """            } else if let firstPhoto = post.photos.first, let uiImage = ImageCache.decode(base64: firstPhoto) {"""
content = content.replace(old_single, new_single)

# For the header pfp 
old_pfp1 = """                        if let data = profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else if let pfp = post.profilePictureBase64, !pfp.isEmpty, let data = Data(base64Encoded: pfp), let uiImage = UIImage(data: data) {"""
new_pfp1 = """                        if let data = profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else if let pfp = post.profilePictureBase64, !pfp.isEmpty, let uiImage = ImageCache.decode(base64: pfp) {"""
content = content.replace(old_pfp1, new_pfp1)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

