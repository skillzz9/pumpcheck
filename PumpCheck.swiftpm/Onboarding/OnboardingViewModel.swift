import SwiftUI
import Observation
import PhotosUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct LiftRecord: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var weight: Double
    var reps: Int
}

@Observable
class OnboardingViewModel {
    // Step 1
    var age: String = ""
    var height: String = ""
    var isHeightCm: Bool = true
    var weight: String = ""
    var isWeightKg: Bool = true
    
    // Step 2
    var yearsLifted: String = ""
    var monthsLifted: String = ""
    var isNatty: Bool = true
    
    // Calorie goal inputs (raw values of BiologicalSex, ActivityLevel, DietGoal)
    var sex: String = ""
    var activityLevel: String = ""
    var dietGoal: String = ""
    
    // Progress
    var progressEntries: [ProgressEntry] = []
    
    // Step 3
    var currentLiftName: String = ""
    var isLiftSelected: Bool = false
    var currentLiftWeight: String = ""
    var currentLiftReps: String = ""
    var proudestLifts: [LiftRecord] = []
    
    var weightPlaceholderText: String {
        let unit = isWeightKg ? "kg" : "lbs"
        let lowerName = currentLiftName.lowercased()
        if lowerName.contains("dumbell") || lowerName.contains("dumbbell") {
            return "Weight per dumbbell (\(unit))"
        } else if lowerName.contains("barbell") || lowerName.contains("bench press") || lowerName.contains("deadlift") || lowerName.contains("squat") {
            return "Weight incl. bar (\(unit))"
        } else {
            return "Weight (\(unit))"
        }
    }
    
    let availableLifts: [(name: String, icon: String)] = [
        ("Bench Press", "figure.strengthtraining.traditional"),
        ("Dumbbell Press", "dumbbell.fill"),
        ("Incline Bench Press", "figure.strengthtraining.traditional"),
        ("Dumbbell Incline Press", "dumbbell.fill"),
        ("Lat Pull Down", "figure.core.training"),
        ("Weighted Pull Up", "figure.highintensity.intervaltraining"),
        ("Deadlift", "figure.strengthtraining.traditional"),
        ("Barbell Squat", "figure.strengthtraining.traditional")
    ]
    
    var filteredLifts: [(name: String, icon: String)] {
        if currentLiftName.isEmpty || isLiftSelected {
            return []
        }
        return availableLifts.filter { $0.name.localizedCaseInsensitiveContains(currentLiftName) }
    }
    
    func selectLift(_ liftName: String) {
        currentLiftName = liftName
        isLiftSelected = true
    }
    
    // Step 4
    var hasSelectedPicture: Bool = false
    var profileImageItem: PhotosPickerItem? = nil
    var profileImageData: Data? = nil
    
    // Step 5
    var currentGoal: String = ""
    var goals: [String] = []
    var kudos: Int = 0
    var blockedUsers: [String] = []
    
    // Step 6 (Now used as Step 1)
    var username: String = ""
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var hasSeenIntro: Bool = false
    
    func addLift() {
        guard !currentLiftName.isEmpty,
              let weightVal = Double(currentLiftWeight.replacingOccurrences(of: ",", with: ".")),
              let repsVal = Int(currentLiftReps) else { return }
        
        let newLift = LiftRecord(name: currentLiftName, weight: weightVal, reps: repsVal)
        proudestLifts.append(newLift)
        
        currentLiftName = ""
        currentLiftWeight = ""
        currentLiftReps = ""
        isLiftSelected = false
    }
    
    func addGoal() {
        let trimmed = currentGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            goals.append(trimmed)
            currentGoal = ""
        }
    }

    var isCreatingAccount: Bool = false
    var errorMessage: String? = nil

    var isLoggingIn: Bool = false
    var loginErrorMessage: String? = nil
    
    func login() async throws {
        isLoggingIn = true
        loginErrorMessage = nil
        
        let safeEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        
        do {
            let result = try await Auth.auth().signIn(withEmail: safeEmail, password: password)
            let uid = result.user.uid
            
            try await fetchUserData(uid: uid)
            
            await MainActor.run {
                self.isLoggingIn = false
            }
        } catch {
            print("Error logging in: \(error.localizedDescription)")
            await MainActor.run {
                self.loginErrorMessage = error.localizedDescription
                self.isLoggingIn = false
            }
            throw error
        }
    }

    func createAccount() async throws {
        isCreatingAccount = true
        errorMessage = nil
        
        let safeEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        
        do {
            let result = try await Auth.auth().createUser(withEmail: safeEmail, password: password)
            let uid = result.user.uid
            
            var photoBase64: String = ""
            if let data = profileImageData, let uiImage = UIImage(data: data) {
                // Compress heavily to stay well under Firestore's 1MB limit
                if let compressedData = uiImage.jpegData(compressionQuality: 0.1) {
                    photoBase64 = compressedData.base64EncodedString()
                }
            }
            
            let db = Firestore.firestore()
            let liftsDict = proudestLifts.map { ["name": $0.name, "weight": $0.weight, "reps": $0.reps] }
            
            let dataToSave: [String: Any] = [
                "username": username,
                "age": age,
                "height": height,
                "isHeightCm": isHeightCm,
                "weight": weight,
                "isWeightKg": isWeightKg,
                "yearsLifted": yearsLifted,
                "monthsLifted": monthsLifted,
                "isNatty": isNatty,
                "sex": sex,
                "activityLevel": activityLevel,
                "dietGoal": dietGoal,
                "goals": goals,
                "kudos": 0,
                "lifts": liftsDict,
                "photoBase64": photoBase64,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("users").document(uid).setData(dataToSave)
            
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
            }
        } catch {
            print("Error creating account: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isCreatingAccount = false
            }
            throw error
        }
    }

    func saveProgressEntry(_ entry: ProgressEntry) {
        progressEntries.append(entry)
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        let liftsDict = entry.lifts.map { ["name": $0.name, "weight": $0.weight, "reps": $0.reps] }
        let data: [String: Any] = [
            "id": entry.id,
            "date": Timestamp(date: entry.date),
            "photoBase64": entry.photoBase64,
            "weight": entry.weight,
            "lifts": liftsDict
        ]
        
        db.collection("users").document(uid).collection("progress").document(entry.id).setData(data)
    }

    func deleteProgressEntry(_ entry: ProgressEntry) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        try await db.collection("users").document(uid).collection("progress").document(entry.id).delete()

        await MainActor.run {
            progressEntries.removeAll { $0.id == entry.id }
        }
    }

    /// Permanently deletes the signed-in user's account and everything they created:
    /// posts, kudos given, comments/replies on other posts, progress entries, and the user document.
    /// Re-authenticates first so Firebase doesn't refuse the final Auth deletion with "requires recent login".
    func deleteAccount(password: String) async throws {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            throw NSError(domain: "PumpCheck", code: 401, userInfo: [NSLocalizedDescriptionKey: "You're not signed in. Please log in again and retry."])
        }
        let uid = user.uid
        let db = Firestore.firestore()
        let posts = db.collection("posts")

        do {
            try await user.reauthenticate(with: EmailAuthProvider.credential(withEmail: email, password: password))
        } catch {
            throw NSError(domain: "PumpCheck", code: 403, userInfo: [NSLocalizedDescriptionKey: "Incorrect password. Please try again."])
        }

        // 1. Their own posts
        let ownPosts = try await posts.whereField("userId", isEqualTo: uid).getDocuments()
        for doc in ownPosts.documents {
            try await doc.reference.delete()
        }

        // 2. Kudos they gave on other people's posts
        let kudoedPosts = try await posts.whereField("kudoedBy", arrayContains: uid).getDocuments()
        for doc in kudoedPosts.documents {
            try await doc.reference.updateData([
                "kudos": FieldValue.increment(Int64(-1)),
                "kudoedBy": FieldValue.arrayRemove([uid])
            ])
            // Author's profile kudos counter is cosmetic; the author may already be deleted, so don't fail on it
            if let authorId = doc.data()["userId"] as? String {
                try? await db.collection("users").document(authorId).updateData(["kudos": FieldValue.increment(Int64(-1))])
            }
        }

        // 3. Comments and replies on other people's posts (stored inline in each post's "comments" array)
        let allPosts = try await posts.getDocuments()
        for doc in allPosts.documents {
            guard let comments = doc.data()["comments"] as? [[String: Any]] else { continue }
            var changed = false
            var kept: [[String: Any]] = []
            for var comment in comments {
                if comment["userId"] as? String == uid {
                    changed = true
                    continue
                }
                if let replies = comment["replies"] as? [[String: Any]] {
                    let filtered = replies.filter { $0["userId"] as? String != uid }
                    if filtered.count != replies.count {
                        comment["replies"] = filtered
                        changed = true
                    }
                }
                kept.append(comment)
            }
            if changed {
                try await doc.reference.updateData(["comments": kept])
            }
        }

        // 4. Progress photos
        let progress = try await db.collection("users").document(uid).collection("progress").getDocuments()
        for doc in progress.documents {
            try await doc.reference.delete()
        }

        // 5. Logged meals
        let meals = try await db.collection("users").document(uid).collection("meals").getDocuments()
        for doc in meals.documents {
            try await doc.reference.delete()
        }

        // 6. Daily calorie summaries
        let dailyCalories = try await db.collection("users").document(uid).collection("dailyCalories").getDocuments()
        for doc in dailyCalories.documents {
            try await doc.reference.delete()
        }

        // 7. Quick adds
        let quickAdds = try await db.collection("users").document(uid).collection("quickAdds").getDocuments()
        for doc in quickAdds.documents {
            try await doc.reference.delete()
        }

        // 8. User document, then the Auth account itself
        try await db.collection("users").document(uid).delete()
        try await user.delete()
    }

    /// Reads a profile stat saved either as text ("21") or as a number (21).
    static func text(_ value: Any?) -> String {
        if let string = value as? String { return string }
        if let number = value as? NSNumber {
            let double = number.doubleValue
            return double.rounded() == double ? String(Int(double)) : String(double)
        }
        return ""
    }

    func saveNutritionSettings() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).updateData([
            "age": age,
            "sex": sex,
            "activityLevel": activityLevel,
            "dietGoal": dietGoal
        ])
    }

    func syncProfileStatsToFirebase() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        let liftsDict = proudestLifts.map { ["name": $0.name, "weight": $0.weight, "reps": $0.reps] }
        let data: [String: Any] = [
            "weight": weight,
            "lifts": liftsDict
        ]
        
        db.collection("users").document(uid).updateData(data)
    }

    func fetchUserData(uid: String) async throws {
        let db = Firestore.firestore()
        let doc = try await db.collection("users").document(uid).getDocument()
        
        guard let data = doc.data() else {
            throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }
        
        // Fetch progress entries
        var fetchedEntries: [ProgressEntry] = []
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
            print("FIREBASE ERROR fetching progress: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = "Firebase Rules Error: \(error.localizedDescription). Please update Firestore rules to allow subcollections."
            }
        }
        await MainActor.run {
            self.username = data["username"] as? String ?? self.username
            
            var currentEntries = fetchedEntries
            
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
            
            self.progressEntries = currentEntries.sorted(by: { $0.date < $1.date })
            self.age = Self.text(data["age"])
            self.height = Self.text(data["height"])
            self.isHeightCm = data["isHeightCm"] as? Bool ?? true
            self.weight = Self.text(data["weight"])
            self.isWeightKg = data["isWeightKg"] as? Bool ?? true
            self.yearsLifted = data["yearsLifted"] as? String ?? ""
            self.monthsLifted = data["monthsLifted"] as? String ?? ""
            self.isNatty = data["isNatty"] as? Bool ?? true
            self.sex = data["sex"] as? String ?? ""
            self.activityLevel = data["activityLevel"] as? String ?? ""
            self.dietGoal = data["dietGoal"] as? String ?? ""
            self.goals = data["goals"] as? [String] ?? []
            self.kudos = data["kudos"] as? Int ?? 0
            self.blockedUsers = data["blockedUsers"] as? [String] ?? []
            
            if let lifts = data["lifts"] as? [[String: Any]] {
                self.proudestLifts = lifts.compactMap { liftDict in
                    guard let name = liftDict["name"] as? String,
                          let w = liftDict["weight"] as? Double,
                          let r = liftDict["reps"] as? Int else { return nil }
                    return LiftRecord(name: name, weight: w, reps: r)
                }
            }
            
            if let base64 = data["photoBase64"] as? String, let imgData = Data(base64Encoded: base64) {
                self.profileImageData = imgData
            }
            
            self.progressEntries = fetchedEntries.sorted(by: { $0.date < $1.date })
        }
    }

}