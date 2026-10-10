import sys

with open("PumpCheck.swiftpm/Onboarding/TestScoringView.swift", "r") as f:
    content = f.read()

old_ui = """                            VStack(spacing: 16) {
                                Text("Score: \\(String(format: "%.1f", res.score))/10")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundColor(Theme.accent)
                                
                                VStack(alignment: .leading, spacing: 8) {"""

new_ui = """                            VStack(spacing: 16) {
                                Text("Score: \\(String(format: "%.1f", res.score))/10")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundColor(Theme.accent)
                                
                                // Badges
                                HStack(spacing: 12) {
                                    VStack(spacing: 4) {
                                        Text("BODY TYPE")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.taupeGrey)
                                        Text(res.bodyType.uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Theme.cardBackground)
                                    .cornerRadius(8)
                                    
                                    VStack(spacing: 4) {
                                        Text("BEST AREA")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.taupeGrey)
                                        Text(res.bestArea.uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Theme.accent)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Theme.cardBackground)
                                    .cornerRadius(8)
                                    
                                    VStack(spacing: 4) {
                                        Text("FOCUS")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.taupeGrey)
                                        Text(res.weakestArea.uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.red.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Theme.cardBackground)
                                    .cornerRadius(8)
                                }
                                .padding(.bottom, 8)
                                
                                VStack(alignment: .leading, spacing: 8) {"""

content = content.replace(old_ui, new_ui)

with open("PumpCheck.swiftpm/Onboarding/TestScoringView.swift", "w") as f:
    f.write(content)

