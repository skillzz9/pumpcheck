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
    var height: String = ""
    var isHeightCm: Bool = true
    var weight: String = ""
    var isWeightKg: Bool = true
    
    // Step 2
    var yearsLifted: String = ""
    var monthsLifted: String = ""
    var isNatty: Bool = true
    
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
                "height": height,
                "isHeightCm": isHeightCm,
                "weight": weight,
                "isWeightKg": isWeightKg,
                "yearsLifted": yearsLifted,
                "monthsLifted": monthsLifted,
                "isNatty": isNatty,
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
            if self.progressEntries.isEmpty {
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
                self.progressEntries = [retroEntry]
            }
            self.height = data["height"] as? String ?? ""
            self.isHeightCm = data["isHeightCm"] as? Bool ?? true
            self.weight = data["weight"] as? String ?? ""
            self.isWeightKg = data["isWeightKg"] as? Bool ?? true
            self.yearsLifted = data["yearsLifted"] as? String ?? ""
            self.monthsLifted = data["monthsLifted"] as? String ?? ""
            self.isNatty = data["isNatty"] as? Bool ?? true
            self.goals = data["goals"] as? [String] ?? []
            self.kudos = data["kudos"] as? Int ?? 0
            
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