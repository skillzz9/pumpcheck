with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "r") as f:
    content = f.read()

target = 'let progressSnapshot = try? await db.collection("users").document(uid).collection("progress").order(by: "date", descending: false).getDocuments()'
replacement = """let progressSnapshot = try? await db.collection("users").document(uid).collection("progress").getDocuments()"""

if target in content:
    content = content.replace(target, replacement)
    
    # Also add sorting before assignment
    target2 = "self.progressEntries = fetchedEntries"
    replacement2 = "self.progressEntries = fetchedEntries.sorted(by: { $0.date < $1.date })"
    content = content.replace(target2, replacement2)
    
    with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "w") as f:
        f.write(content)
    print("Patched successfully!")
else:
    print("Target not found!")
