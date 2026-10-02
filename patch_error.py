with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "r") as f:
    content = f.read()

target = """        let progressSnapshot = try? await db.collection("users").document(uid).collection("progress").getDocuments()
        
        var fetchedEntries: [ProgressEntry] = []"""

replacement = """        var fetchedEntries: [ProgressEntry] = []
        do {
            let progressSnapshot = try await db.collection("users").document(uid).collection("progress").getDocuments()
            if let docs = progressSnapshot.documents as? [QueryDocumentSnapshot] {
                for pDoc in docs {
                    let pData = pDoc.data()
                    let id = pData["id"] as? String ?? pDoc.documentID
                    let ts = pData["date"] as? Timestamp
                    let date = ts?.dateValue() ?? Date()
                    let photoBase64 = pData["photoBase64"] as? String ?? ""
                    let weight = pData["weight"] as? String ?? ""
                    
                    var entryLifts: [LiftRecord] = []
                    if let liftsDictArray = pData["lifts"] as? [[String: Any]] {
                        entryLifts = liftsDictArray.compactMap { dict in
                            guard let n = dict["name"] as? String,
                                  let w = dict["weight"] as? Double,
                                  let r = dict["reps"] as? Int else { return nil }
                            return LiftRecord(name: n, weight: w, reps: r)
                        }
                    }
                    
                    let entry = ProgressEntry(id: id, date: date, photoBase64: photoBase64, weight: weight, lifts: entryLifts)
                    fetchedEntries.append(entry)
                }
            }
        } catch {
            print("FIREBASE ERROR fetching progress: \\(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Firebase Rules Error: \\(error.localizedDescription). Please update Firestore rules to allow subcollections."
            }
        }"""

# Remove the old if let docs = progressSnapshot?.documents block because we inlined it in the do-catch
import re
content = content.replace(target, replacement)
content = re.sub(r'if let docs = progressSnapshot\?\.documents \{[\s\S]*?\}\s*await MainActor\.run', 'await MainActor.run', content)

with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "w") as f:
    f.write(content)
print("Patched successfully!")
