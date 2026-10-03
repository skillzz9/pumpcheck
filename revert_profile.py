with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content = f.read()

content = content.replace("import IrregularGradient\n", "")

target = """                        IrregularGradient(
                            colors: [Theme.accent, Color.purple, Color.indigo, Color.blue, Color.cyan],
                            background: Theme.pitchBlack,
                            speed: 0.5
                        )"""
replacement = "                        Color.white"

if target in content:
    content = content.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
        f.write(content)
    print("Patched ProfileView successfully!")
else:
    print("Target not found!")
