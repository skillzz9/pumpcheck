import sys

with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "r") as f:
    content = f.read()

old_btn = """                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.pitchBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background((isSignedUp && !isCheckingStatus) ? Color.green : Theme.accent)
                            .cornerRadius(16)
                            .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)"""

new_btn = """                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor((isSignedUp && !isCheckingStatus) ? Theme.textPrimary : Theme.pitchBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background((isSignedUp && !isCheckingStatus) ? Theme.cardBackground : Theme.accent)
                            .cornerRadius(16)
                            .shadow(color: (isSignedUp && !isCheckingStatus) ? .clear : Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)"""

content = content.replace(old_btn, new_btn)

with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "w") as f:
    f.write(content)

