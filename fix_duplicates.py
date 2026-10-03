import re

with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "r") as f:
    content = f.read()

# Replace duplicate logic and delete the retroactive block
target = """            var currentEntries = fetchedEntries
            
            // Clean up duplicate entries caused by the previous initialization bug.
            var uniqueDates = Set<Date>()
            var duplicatesToDelete: [ProgressEntry] = []
            var cleanEntries: [ProgressEntry] = []
            
            for entry in currentEntries {
                if uniqueDates.contains(entry.date) {
                    duplicatesToDelete.append(entry)
                } else {
                    uniqueDates.insert(entry.date)
                    cleanEntries.append(entry)
                }
            }
            
            for dup in duplicatesToDelete {
                Task {
                    try? await db.collection("users").document(uid).collection("progress").document(dup.id).delete()
                }
            }
            currentEntries = cleanEntries
            
            // Retroactive fix for empty calendar
            if currentEntries.isEmpty {
                let initialEntryId = UUID().uuidString
                let originalDate = data["createdAt"] ?? FieldValue.serverTimestamp()
                
                let progressData: [String: Any] = [
                    "id": initialEntryId,
                    "date": originalDate,
                    "photoBase64": data["photoBase64"] as? String ?? "",
                    "weight": data["weight"] as? String ?? "",
                    "lifts": data["lifts"] as? [[String: Any]] ?? []
                ]
                
                // Write retroactively in the background
                Task {
                    try? await db.collection("users").document(uid).collection("progress").document(initialEntryId).setData(progressData)
                }
                
                // Add to local state so it shows up instantly without reloading
                var retroLifts: [LiftRecord] = []
                if let liftsDictArray = data["lifts"] as? [[String: Any]] {
                    retroLifts = liftsDictArray.compactMap { dict in
                        guard let n = dict["name"] as? String,
                              let w = dict["weight"] as? Double,
                              let r = dict["reps"] as? Int else { return nil }
                        return LiftRecord(name: n, weight: w, reps: r)
                    }
                }
                let ts = data["createdAt"] as? Timestamp
                let retroEntry = ProgressEntry(
                    id: initialEntryId,
                    date: ts?.dateValue() ?? Date(),
                    photoBase64: data["photoBase64"] as? String ?? "",
                    weight: data["weight"] as? String ?? "",
                    lifts: retroLifts
                )
                currentEntries = [retroEntry]
            }
            
            self.progressEntries = currentEntries"""

replacement = """            var currentEntries = fetchedEntries
            
            // Clean up duplicate entries (comparing strictly by day, ignoring exact time)
            var uniqueDays = Set<Date>()
            var duplicatesToDelete: [ProgressEntry] = []
            var cleanEntries: [ProgressEntry] = []
            
            for entry in currentEntries {
                let startOfDay = Calendar.current.startOfDay(for: entry.date)
                if uniqueDays.contains(startOfDay) {
                    duplicatesToDelete.append(entry)
                } else {
                    uniqueDays.insert(startOfDay)
                    cleanEntries.append(entry)
                }
            }
            
            for dup in duplicatesToDelete {
                Task {
                    try? await db.collection("users").document(uid).collection("progress").document(dup.id).delete()
                }
            }
            currentEntries = cleanEntries
            
            // Note: We removed the retroactive auto-population here!
            // Auto-population now ONLY happens in createAccount() on first sign-up.
            
            self.progressEntries = currentEntries.sorted(by: { $0.date < $1.date })"""

if target in content:
    content = content.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "w") as f:
        f.write(content)
    print("Patched successfully!")
else:
    print("Target not found! Attempting regex match...")
    
