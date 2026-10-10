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
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.accent.opacity(0.3), lineWidth: 1))"""


new_ui = """                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Areas to Improve")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    
                                    ForEach(res.areasToImprove, id: \\.self) { area in
                                        HStack(alignment: .top, spacing: 8) {
                                            Circle()
                                                .fill(Theme.accent)
                                                .frame(width: 6, height: 6)
                                                .padding(.top, 6)
                                            Text(area)
                                                .font(.system(size: 14))
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                    }
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
                                        HStack(alignment: .center, spacing: 16) {
                                            Text("\\(index + 1)")
                                                .font(.system(size: 16, weight: .black, design: .rounded))
                                                .foregroundColor(Theme.pitchBlack)
                                                .frame(width: 32, height: 32)
                                                .background(Theme.accent)
                                                .clipShape(Circle())
                                            
                                            Text(exercise)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(Theme.textPrimary)
                                            
                                            Spacer()
                                        }
                                        .padding(16)
                                        .background(Theme.cardBackground)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Theme.taupeGrey.opacity(0.2), lineWidth: 1)
                                        )
                                        .shadow(color: Theme.accent.opacity(0.1), radius: 5, x: 0, y: 2)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)"""

content = content.replace(old_ui, new_ui)

with open("PumpCheck.swiftpm/Onboarding/TestScoringView.swift", "w") as f:
    f.write(content)

