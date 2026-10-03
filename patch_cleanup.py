with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "r") as f:
    content = f.read()

target = """            self.username = data["username"] as? String ?? self.username
            
            // Retroactive fix for empty calendar
            if self.progressEntries.isEmpty {"""

replacement = """            self.username = data["username"] as? String ?? self.username
            
            // Force cleanup bad retroactive entry for hugoesgym
            if self.progressEntries.count == 1, 
               let first = self.progressEntries.first, 
               Date().timeIntervalSince(first.date) < 3600 {
                
                let originalTs = data["createdAt"] as? Timestamp
                if let oDate = originalTs?.dateValue(), abs(oDate.timeIntervalSince(first.date)) > 86400 {
                    // It was created today, but account was created >1 day ago. This is the bad retro entry!
                    Task {
                        try? await db.collection("users").document(uid).collection("progress").document(first.id).delete()
                    }
                    self.progressEntries.removeAll()
                }
            }
            
            // Retroactive fix for empty calendar
            if self.progressEntries.isEmpty {"""

if target in content:
    content = content.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "w") as f:
        f.write(content)
    print("Patched successfully!")
else:
    print("Target not found!")
