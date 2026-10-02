with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "r") as f:
    content = f.read()

target = """            try await db.collection("users").document(uid).setData(dataToSave)
            
            await MainActor.run {
                self.isCreatingAccount = false
            }"""

replacement = """            try await db.collection("users").document(uid).setData(dataToSave)
            
            // Auto-generate initial progress entry
            let initialEntryId = UUID().uuidString
            let progressData: [String: Any] = [
                "id": initialEntryId,
                "date": FieldValue.serverTimestamp(),
                "photoBase64": photoBase64,
                "weight": weight,
                "lifts": liftsDict
            ]
            try await db.collection("users").document(uid).collection("progress").document(initialEntryId).setData(progressData)
            
            let initialEntry = ProgressEntry(
                id: initialEntryId,
                date: Date(),
                photoBase64: photoBase64,
                weight: weight,
                lifts: proudestLifts
            )
            
            await MainActor.run {
                self.progressEntries = [initialEntry]
                self.isCreatingAccount = false
            }"""

if target in content:
    content = content.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "w") as f:
        f.write(content)
    print("Patched successfully!")
else:
    print("Target not found!")
