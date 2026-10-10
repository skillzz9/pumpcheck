import sys

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content = f.read()

old_gallery = """                    let currentIndex = Int(sliderValue)
                    if currentIndex >= 0 && currentIndex < photos.count,
                       let data = Data(base64Encoded: photos[currentIndex]),
                       let uiImage = UIImage(data: data) {
                        
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

new_gallery = """                    let currentIndex = Int(sliderValue)
                    if currentIndex >= 0 && currentIndex < photos.count,
                       let uiImage = ImageCache.decode(base64: photos[currentIndex]) {
                        
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

content = content.replace(old_gallery, new_gallery)

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
    f.write(content)

