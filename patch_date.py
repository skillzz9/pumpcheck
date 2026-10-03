with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "r") as f:
    content = f.read()

target = """            // Retroactive fix for empty calendar
            if self.progressEntries.isEmpty {
                let initialEntryId = UUID().uuidString
                let progressData: [String: Any] = [
                    "id": initialEntryId,
                    "date": FieldValue.serverTimestamp(),"""

replacement = """            // Retroactive fix for empty calendar
            if self.progressEntries.isEmpty {
                let initialEntryId = UUID().uuidString
                let originalDate = data["createdAt"] ?? FieldValue.serverTimestamp()
                
                let progressData: [String: Any] = [
                    "id": initialEntryId,
                    "date": originalDate,"""

if target in content:
    content = content.replace(target, replacement)
else:
    print("Target 1 not found!")

target2 = """                let retroEntry = ProgressEntry(
                    id: initialEntryId,
                    date: Date(),"""

replacement2 = """                let ts = data["createdAt"] as? Timestamp
                let retroEntry = ProgressEntry(
                    id: initialEntryId,
                    date: ts?.dateValue() ?? Date(),"""

if target2 in content:
    content = content.replace(target2, replacement2)
else:
    print("Target 2 not found!")

with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "w") as f:
    f.write(content)
print("Patched successfully!")
