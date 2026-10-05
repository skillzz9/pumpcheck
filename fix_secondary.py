import sys

with open("PumpCheck.swiftpm/Onboarding/Theme.swift", "r") as f:
    content = f.read()

content = content.replace("static let textSecondary = paleSky.opacity(0.7)", "static let textSecondary = taupeGrey")

with open("PumpCheck.swiftpm/Onboarding/Theme.swift", "w") as f:
    f.write(content)

