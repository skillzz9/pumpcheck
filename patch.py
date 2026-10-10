with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "r") as f:
    text = f.read()

text = text.replace("}\n        .navigationTitle", "}\n        }\n        .navigationTitle")

with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "w") as f:
    f.write(text)

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    text2 = f.read()

text2 = text2.replace("}\n            .navigationDestination", "}\n        }\n        .navigationDestination")

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
    f.write(text2)
