with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content = f.read()

target = """                        IrregularGradient(
                            colors: [Color.white, Theme.accent.opacity(0.15), Color.blue.opacity(0.1), Color.white, Color.purple.opacity(0.1)],
                            background: Color.white,
                            speed: 4
                        )"""

replacement = """                        IrregularGradient(
                            colors: [Theme.accent, Color.purple, Color.indigo, Color.blue, Color.cyan],
                            background: Theme.pitchBlack,
                            speed: 0.5
                        )"""

if target in content:
    content = content.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
        f.write(content)
    print("Patched gradient successfully!")
else:
    print("Target not found!")
