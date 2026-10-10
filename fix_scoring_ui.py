import sys

with open("PumpCheck.swiftpm/Onboarding/TestScoringView.swift", "r") as f:
    content = f.read()

old_ui = """                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Areas to Improve")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text(res.areasToImprove)
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        }"""

new_ui = """                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Areas to Improve")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    Text(res.areasToImprove)
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Action Plan: 5 Recommended Exercises")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    
                                    ForEach(Array(res.recommendedExercises.enumerated()), id: \\.offset) { index, exercise in
                                        HStack(alignment: .top, spacing: 12) {
                                            Text("\\(index + 1)")
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundColor(Theme.cardBackground)
                                                .frame(width: 24, height: 24)
                                                .background(Theme.accent)
                                                .clipShape(Circle())
                                            
                                            Text(exercise)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(Theme.textSecondary)
                                                .padding(.top, 2)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.accent.opacity(0.3), lineWidth: 1))
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        }"""

content = content.replace(old_ui, new_ui)

with open("PumpCheck.swiftpm/Onboarding/TestScoringView.swift", "w") as f:
    f.write(content)

