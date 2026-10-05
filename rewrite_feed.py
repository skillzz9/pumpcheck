import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

old_header = """                    HStack(spacing: 12) {
                        if let pfp = post.profilePictureBase64, !pfp.isEmpty, let data = Data(base64Encoded: pfp), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Theme.taupeGrey.opacity(0.5))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String(post.username.prefix(1).uppercased()))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                )
                        }"""

new_header = """                    HStack(spacing: 12) {
                        if let data = profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else if let pfp = post.profilePictureBase64, !pfp.isEmpty, let data = Data(base64Encoded: pfp), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Theme.taupeGrey.opacity(0.5))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(String(post.username.prefix(1).uppercased()))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                )
                        }"""

content = content.replace(old_header, new_header)

old_onappear = """        .padding(.top, 16)
        .padding(.bottom, 24)
    }"""

new_onappear = """        .padding(.top, 16)
        .padding(.bottom, 24)
        .task {
            let db = Firestore.firestore()
            if let doc = try? await db.collection("users").document(post.userId).getDocument(),
               let b64 = doc.data()?["photoBase64"] as? String,
               !b64.isEmpty,
               let d = Data(base64Encoded: b64) {
                await MainActor.run {
                    self.profileImageData = d
                }
            }
        }
    }"""

content = content.replace(old_onappear, new_onappear)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

