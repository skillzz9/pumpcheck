import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

# Fix currentIndex in FeedView
old_idx = "let currentIndex = Int(sliderValue)"
new_idx = "let currentIndex = Int(round(sliderValue))"
content = content.replace(old_idx, new_idx)

# Fix slider in FeedView
old_slider = """                        Slider(value: $sliderValue, in: 0...Double(post.photos.count - 1), step: 1.0)"""

new_slider = """                        Slider(value: $sliderValue, in: 0...Double(post.photos.count - 1), onEditingChanged: { editing in
                            if !editing {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    sliderValue = round(sliderValue)
                                }
                            }
                        })"""

content = content.replace(old_slider, new_slider)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

