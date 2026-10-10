with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    text = f.read()

text = text.replace("}\n\nstruct ProgressFlickerGallery: View {", "}\n}\n\nstruct ProgressFlickerGallery: View {")

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
    f.write(text)
