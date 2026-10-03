with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

target = """            // Image (1/3 of screen)
            GeometryReader { geo in
                Rectangle()
                    .fill(Theme.cardBackground)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.taupeGrey.opacity(0.5))
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .frame(height: UIScreen.main.bounds.height / 3)"""

replacement = """            // Image (1/3 of screen)
            GeometryReader { geo in
                if let data = Data(base64Encoded: post.photoBase64), let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Theme.cardBackground)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.taupeGrey.opacity(0.5))
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            }
            .frame(height: UIScreen.main.bounds.height / 3)"""

if target in content:
    content = content.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
        f.write(content)
    print("Patched CommentModalView successfully!")
else:
    print("Target not found!")
