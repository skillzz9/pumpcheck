with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "r") as f:
    content = f.read()

target = "ProgressDetailView(entry: entry, isWeightKg: viewModel.isWeightKg) { selectedEntry = nil }"
replacement = "ProgressDetailView(initialEntry: entry, allEntries: viewModel.progressEntries, isWeightKg: viewModel.isWeightKg) { selectedEntry = nil }"

if target in content:
    content = content.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "w") as f:
        f.write(content)
    print("Patched ProgressTab successfully!")
else:
    print("Target not found!")
