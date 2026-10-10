import sys

with open("PumpCheck.swiftpm/Onboarding/ProgressDetailView.swift", "r") as f:
    content = f.read()

old_layout = """                        if let data = Data(base64Encoded: currentEntry.photoBase64), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 24)
                        }"""

new_layout = """                        if let uiImage = ImageCache.decode(base64: currentEntry.photoBase64) {
                            Color.clear
                                .aspectRatio(9.0 / 16.0, contentMode: .fit)
                                .overlay(
                                    ZStack {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .blur(radius: 20)
                                            .opacity(0.5)
                                            
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                    }
                                )
                                .clipped()
                                .background(Theme.pitchBlack)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 24)
                        }"""

content = content.replace(old_layout, new_layout)

with open("PumpCheck.swiftpm/Onboarding/ProgressDetailView.swift", "w") as f:
    f.write(content)

