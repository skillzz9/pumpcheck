import SwiftUI
import FirebaseFirestore
import Charts

struct PublicProfileView: View {
    let userId: String
    let username: String
    
    @State private var profileImageData: Data? = nil
    @State private var kudos: Int = 0
    @State private var height: String = ""
    @State private var weight: String = ""
    @State private var age: String = ""
    @State private var yearsLifted: String = ""
    @State private var monthsLifted: String = ""
    @State private var isHeightCm: Bool = true
    @State private var isWeightKg: Bool = true
    @State private var proudestLifts: [LiftRecord] = []
    @State private var progressPhotos: [String] = []
    @State private var isLoading = true
    
    @State private var navToStats: Bool = false
    @State private var initialStatSelection: StatSelection = .height
    
    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                    .scaleEffect(1.5)
            } else {
                ScrollView {
                VStack(spacing: 32) {
                    
                    // TOP HALF
                    VStack(spacing: 32) {
                        // Profile Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Theme.cardBackground)
                                    .frame(width: 140, height: 140)
                                    .shadow(color: Theme.accent.opacity(0.2), radius: 20, x: 0, y: 10)
                                
                                if let data = profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 140)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 140, height: 140)
                                        .foregroundColor(Theme.taupeGrey.opacity(0.5))
                                }
                            }
                            
                            VStack(spacing: 4) {
                                Text(username)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                
                                let y = yearsLifted
                                let m = monthsLifted
                                let expStr = (!y.isEmpty && y != "0" ? "\(y)y " : "") + (!m.isEmpty && m != "0" ? "\(m)m " : "")
                                let finalExp = expStr.isEmpty ? "Just started" : expStr + "lifting"
                                let ageStr = age.isEmpty ? "" : "\(age)yo • "
                                
                                Text(ageStr + finalExp)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                        
                        // Stats row
                        HStack(spacing: 12) {
                            // Height Pill
                            Button { initialStatSelection = .height; navToStats = true } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "ruler.fill")
                                        .foregroundColor(Theme.accent)
                                    Text("\(height.isEmpty ? "--" : height) \(isHeightCm ? "cm" : "in")")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)
                                }
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Theme.cardBackground)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Theme.taupeGrey.opacity(0.2), lineWidth: 1))
                            }
                            
                            // Weight Pill
                            Button { initialStatSelection = .weight; navToStats = true } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "scalemass.fill")
                                        .foregroundColor(Theme.accent)
                                    Text("\(weight.isEmpty ? "--" : weight) \(isWeightKg ? "kg" : "lbs")")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)
                                }
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Theme.cardBackground)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Theme.taupeGrey.opacity(0.2), lineWidth: 1))
                            }
                            
                            // Kudos Pill
                            HStack(spacing: 6) {
                                Image(systemName: "hand.thumbsup.fill")
                                    .foregroundColor(Theme.accent)
                                Text("\(kudos)")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Theme.cardBackground)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.taupeGrey.opacity(0.2), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 24)
                    .background(
                        Theme.paleSky.padding(.top, -1000)
                    )
                    
                    // BOTTOM HALF
                    VStack(alignment: .leading, spacing: 32) {
                        // Lifts
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Proudest Lifts")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                            
                            if proudestLifts.isEmpty {
                                Text("No lifts recorded yet.")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(Theme.textSecondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Theme.cardBackground)
                                    .cornerRadius(16)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(proudestLifts) { lift in
                                        Button { initialStatSelection = .lift(lift.name); navToStats = true } label: {
                                            HStack {
                                                Text(lift.name)
                                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                    .foregroundColor(Theme.textPrimary)
                                                Spacer()
                                                Text("\(lift.weight, specifier: "%.1f") × \(lift.reps)")
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundColor(Theme.accent)
                                            }
                                            .padding()
                                            .background(Theme.cardBackground)
                                            .cornerRadius(16)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Progress Flicker Gallery
                        ProgressFlickerGallery(photos: progressPhotos)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
            }
        }
        }
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchPublicProfile()
        }
        .navigationDestination(isPresented: $navToStats) {
            StatsView(userId: userId, username: username, heightStr: height, weightStr: weight, lifts: proudestLifts, selection: initialStatSelection)
        }
        
        
        
    }
    
    
    
    private func fetchPublicProfile() async {
        let db = Firestore.firestore()
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            if let data = doc.data() {
                let base64 = data["photoBase64"] as? String ?? ""
                if !base64.isEmpty, let imgData = Data(base64Encoded: base64) {
                    profileImageData = imgData
                }
                
                kudos = data["kudos"] as? Int ?? 0
                height = data["height"] as? String ?? ""
                weight = data["weight"] as? String ?? ""
                age = data["age"] as? String ?? ""
                yearsLifted = data["yearsLifted"] as? String ?? ""
                monthsLifted = data["monthsLifted"] as? String ?? ""
                isHeightCm = data["isHeightCm"] as? Bool ?? true
                isWeightKg = data["isWeightKg"] as? Bool ?? true
                
                if let lifts = data["lifts"] as? [[String: Any]] {
                    proudestLifts = lifts.compactMap { liftDict in
                        guard let name = liftDict["name"] as? String,
                              let w = liftDict["weight"] as? Double,
                              let r = liftDict["reps"] as? Int else { return nil }
                        return LiftRecord(name: name, weight: w, reps: r)
                    }
                }
            }
            
            // Fetch progress photos
            let progressSnapshot = try await db.collection("users").document(userId).collection("progress").order(by: "date", descending: false).getDocuments()
            var pPhotos: [String] = []
            for pDoc in progressSnapshot.documents {
                if let photoStr = pDoc.data()["photoBase64"] as? String, !photoStr.isEmpty {
                    pPhotos.append(photoStr)
                }
            }
            progressPhotos = pPhotos
            
        } catch {
            print("Error fetching profile: \(error)")
        }
        isLoading = false
    }
}

