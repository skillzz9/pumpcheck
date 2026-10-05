import sys

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "r") as f:
    content = f.read()

old_idx = "let currentIndex = min(max(Int(sliderValue), 0), sortedEntries.count - 1)"
new_idx = "let currentIndex = min(max(Int(round(sliderValue)), 0), sortedEntries.count - 1)"
content = content.replace(old_idx, new_idx)

old_slider = """                            if sortedEntries.count > 1 {
                                VStack(spacing: 4) {
                                    Slider(value: $sliderValue, in: 0...Double(sortedEntries.count - 1), step: 1.0)
                                        .tint(Theme.accent)
                                    
                                    Text(currentEntry.date.formatted(.dateTime.year().month().day()))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Theme.taupeGrey)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Theme.pitchBlack)
                            } else {"""

new_slider = """                            if sortedEntries.count > 1 {
                                VStack(spacing: 8) {
                                    GeometryReader { geo in
                                        let trackWidth = geo.size.width - 28
                                        let percentage = CGFloat(sliderValue / Double(sortedEntries.count - 1))
                                        let thumbX = 14 + (percentage * trackWidth)
                                        
                                        Text(currentEntry.date.formatted(.dateTime.year().month().day()))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.taupeGrey)
                                            .position(x: thumbX, y: geo.size.height / 2)
                                    }
                                    .frame(height: 14)
                                    
                                    Slider(value: $sliderValue, in: 0...Double(sortedEntries.count - 1)) { editing in
                                        if !editing {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                sliderValue = round(sliderValue)
                                            }
                                        }
                                    }
                                    .tint(Theme.accent)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Theme.pitchBlack)
                            } else {"""

content = content.replace(old_slider, new_slider)

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "w") as f:
    f.write(content)

