import sys

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content = f.read()

if "import FirebaseFirestore" not in content:
    content = content.replace("import FirebaseAuth", "import FirebaseAuth\nimport FirebaseFirestore")
    with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
        f.write(content)
