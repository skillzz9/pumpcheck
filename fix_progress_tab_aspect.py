import re

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "r") as f:
    content = f.read()

# Let's check how the Image is constrained in ProgressTab.swift
# We can change it to have a maxHeight so it doesn't take up the whole screen.

content = content.replace(".aspectRatio(1.0, contentMode: .fit)", ".aspectRatio(9.0 / 16.0, contentMode: .fit)\n                                    .frame(maxHeight: 450)")

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "w") as f:
    f.write(content)

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content2 = f.read()

content2 = content2.replace(".aspectRatio(1.0, contentMode: .fit)", ".aspectRatio(9.0 / 16.0, contentMode: .fit)\n                            .frame(maxHeight: 450)")

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
    f.write(content2)
    
with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "r") as f:
    content3 = f.read()

content3 = content3.replace(".aspectRatio(1.0, contentMode: .fit)", ".aspectRatio(9.0 / 16.0, contentMode: .fit)\n                            .frame(maxHeight: 450)")

with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "w") as f:
    f.write(content3)
