import sys

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "r") as f:
    content = f.read()

old_layout = """                            if let uiImage = ImageCache.decode(base64: currentEntry.photoBase64) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(9.0 / 16.0, contentMode: .fit)
                                    .clipped()
                            } else {
                                Rectangle()
                                    .fill(Theme.cardBackground)
                                    .aspectRatio(9.0 / 16.0, contentMode: .fit)
                            }"""

new_layout = """                            if let uiImage = ImageCache.decode(base64: currentEntry.photoBase64) {
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
                            } else {
                                Rectangle()
                                    .fill(Theme.cardBackground)
                                    .aspectRatio(9.0 / 16.0, contentMode: .fit)
                            }"""

content = content.replace(old_layout, new_layout)

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "w") as f:
    f.write(content)

