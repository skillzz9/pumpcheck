import re

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content = f.read()

# Add import
if "import IrregularGradient" not in content:
    content = content.replace("import SwiftUI\nimport FirebaseAuth", "import SwiftUI\nimport FirebaseAuth\nimport IrregularGradient")

# Replace background
target = """                    .background(
                        Color.white
                            .padding(.top, -1000)
                            .padding(.horizontal, -24)
                    )"""

replacement = """                    .background(
                        IrregularGradient(
                            colors: [Color.white, Theme.accent.opacity(0.15), Color.blue.opacity(0.1), Color.white, Color.purple.opacity(0.1)],
                            background: Color.white,
                            speed: 4
                        )
                        .padding(.top, -1000)
                        .padding(.horizontal, -24)
                    )"""

if target in content:
    content = content.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
        f.write(content)
    print("Patched ProfileView successfully!")
else:
    print("Target not found!")
