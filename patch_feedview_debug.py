import re

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

target = """                Text(post.username)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)"""

replacement = """                Text(post.username)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text("\\(post.photos.count) photos")
                    .font(.caption)
                    .foregroundColor(Theme.accent)"""

content = content.replace(target, replacement)

target2 = """                TabView {
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
                .clipped()"""

replacement2 = """                TabView {
                    ForEach(post.photos.indices, id: \\.self) { idx in
                        if let data = Data(base64Encoded: post.photos[idx]), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                        } else {
                            VStack {
                                Text("Failed to load photo \\(idx)").foregroundColor(.red)
                            }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(maxWidth: .infinity)
                .aspectRatio(1.0, contentMode: .fit)
                .clipped()
                .background(Color.gray.opacity(0.1))"""

content = content.replace(target2, replacement2)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

print("Patched FeedView for debugging!")
