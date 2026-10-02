with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "r") as f:
    content = f.read()

target = """            self.username = data["username"] as? String ?? self.username"""

replacement = """            self.username = data["username"] as? String ?? self.username
            
            // Retroactive fix for empty calendar
            if self.progressEntries.isEmpty {
                let initialEntryId = UUID().uuidString
                let progressData: [String: Any] = [
                    "id": initialEntryId,
                    "date": FieldValue.serverTimestamp(),
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
                let retroEntry = ProgressEntry(
                    id: initialEntryId,
                    date: Date(),
                    photoBase64: data["photoBase64"] as? String ?? "",
                    weight: data["weight"] as? String ?? "",
                    lifts: retroLifts
                )
                self.progressEntries = [retroEntry]
            }"""

if target in content:
    content = content.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "w") as f:
        f.write(content)
    print("Patched successfully!")
else:
    print("Target not found!")
