import sys

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "r") as f:
    content = f.read()

old_slider = """                                    Slider(value: $sliderValue, in: 0...Double(sortedEntries.count - 1)) { editing in
                                        if !editing {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                sliderValue = round(sliderValue)
                                            }
                                        }
                                    }
                                    .tint(Theme.accent)"""

new_slider = """                                    Slider(value: $sliderValue, in: 0...Double(sortedEntries.count - 1), onEditingChanged: { editing in
                                        if !editing {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                sliderValue = round(sliderValue)
                                            }
                                        }
                                    })
                                    .tint(Theme.accent)"""

content = content.replace(old_slider, new_slider)

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "w") as f:
    f.write(content)

