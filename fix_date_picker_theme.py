import sys

with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "r") as f:
    content = f.read()

old_picker = """                            .background(Theme.cardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)"""

new_picker = """                            .background(Theme.cardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                            .environment(\\.colorScheme, .dark)"""

content = content.replace(old_picker, new_picker)

with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "w") as f:
    f.write(content)

