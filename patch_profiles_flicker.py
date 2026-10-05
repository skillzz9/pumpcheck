import re

# 1. Create the ProgressFlickerGallery component
flicker_gallery_code = """
struct ProgressFlickerGallery: View {
    let photos: [String] // Array of base64 strings
    @State private var sliderValue: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Physique Progress")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            
            if photos.isEmpty {
                Text("No progress photos yet.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.cardBackground)
                    .cornerRadius(16)
            } else {
                VStack(spacing: 0) {
                    let currentIndex = Int(sliderValue)
                    if currentIndex >= 0 && currentIndex < photos.count,
                       let data = Data(base64Encoded: photos[currentIndex]),
                       let uiImage = UIImage(data: data) {
                        
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1.0, contentMode: .fit)
                            .clipped()
                            
                    } else {
                        Rectangle()
                            .fill(Theme.cardBackground)
                            .aspectRatio(1.0, contentMode: .fit)
                    }
                    
                    if photos.count > 1 {
                        VStack(spacing: 4) {
                            Slider(value: $sliderValue, in: 0...Double(photos.count - 1), step: 1.0)
                                .tint(Theme.accent)
                            
                            HStack {
                                Text("Earliest")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.taupeGrey)
                                Spacer()
                                Text("Latest")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.taupeGrey)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    } else {
                        Text("1 Photo")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Theme.taupeGrey)
                            .padding(.vertical, 12)
                    }
                }
                .background(Color.black.opacity(0.2))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.taupeGrey.opacity(0.2), lineWidth: 1))
            }
        }
    }
}
"""

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content = f.read()

if "struct ProgressFlickerGallery" not in content:
    content += flicker_gallery_code

target_goals = """                    // Goals
                    VStack(alignment: .leading, spacing: 16) {"""

replacement_goals = """                    // Progress Flicker Gallery
                    let photoArray = viewModel.progressEntries.sorted(by: { $0.date < $1.date }).map { $0.photoBase64 }.filter { !$0.isEmpty }
                    ProgressFlickerGallery(photos: photoArray)
                    
                    // Goals
                    VStack(alignment: .leading, spacing: 16) {"""

content = content.replace(target_goals, replacement_goals)
with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
    f.write(content)

with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "r") as f:
    pub_content = f.read()

target_state = """    @State private var proudestLifts: [LiftRecord] = []"""
replacement_state = """    @State private var proudestLifts: [LiftRecord] = []
    @State private var progressPhotos: [String] = []"""
pub_content = pub_content.replace(target_state, replacement_state)

target_pub_goals = """                        Spacer(minLength: 40)
                    }
                    .padding(.top, 40)"""

replacement_pub_goals = """                        // Progress Flicker Gallery
                        ProgressFlickerGallery(photos: progressPhotos)
                            .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 40)"""
pub_content = pub_content.replace(target_pub_goals, replacement_pub_goals)

target_fetch = """                if let lifts = data["lifts"] as? [[String: Any]] {
                    proudestLifts = lifts.compactMap { liftDict in
                        guard let name = liftDict["name"] as? String,
                              let w = liftDict["weight"] as? Double,
                              let r = liftDict["reps"] as? Int else { return nil }
                        return LiftRecord(name: name, weight: w, reps: r)
                    }
                }
            }
        } catch {"""

replacement_fetch = """                if let lifts = data["lifts"] as? [[String: Any]] {
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
            
        } catch {"""
pub_content = pub_content.replace(target_fetch, replacement_fetch)

with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "w") as f:
    f.write(pub_content)

print("Patched profiles with ProgressFlickerGallery!")
