import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Charts

struct ProfileView: View {
    var viewModel: OnboardingViewModel
    
    @State private var navToStats: Bool = false
    @State private var initialStatSelection: StatSelection = .height
    @State private var showDeleteConfirm = false
    @State private var deletePassword = ""
    @State private var isDeletingAccount = false
    @State private var deleteError: String? = nil
    @State private var showPhotoPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
            Theme.bgGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // TOP HALF
                    VStack(spacing: 12) {
                        // Profile Header
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Theme.cardBackground)
                                    .frame(width: 216, height: 216)
                                    .shadow(color: Theme.accent.opacity(0.2), radius: 20, x: 0, y: 10)
                                
                                if let data = viewModel.profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 216, height: 216)
                                        .clipShape(Circle())
                                } else {
                                    // No photo yet: the first progress photo becomes the profile picture
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(Theme.accent)
                                        Text("Go to Progress\nto upload")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(Theme.textSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(width: 216, height: 216)
                                    .overlay(
                                        Circle()
                                            .stroke(Theme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                                    )
                                }
                                
                                if viewModel.isNatty {
                                    HStack(spacing: 2) {
                                        Text("Natty")
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.accent)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Theme.paleSky, lineWidth: 2)
                                    )
                                    .shadow(color: Theme.accent.opacity(0.3), radius: 3, x: 0, y: 2)
                                    .offset(x: 78, y: -96)
                                }

                                // Edit badge: the picture can be changed to any progress diary photo
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.pitchBlack)
                                    .frame(width: 36, height: 36)
                                    .background(Theme.accent)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Theme.paleSky, lineWidth: 3))
                                    .offset(x: 76, y: 78)
                            }
                            .contentShape(Circle())
                            .onTapGesture { showPhotoPicker = true }
                            
                            VStack(spacing: 2) {
                                Text("@\(viewModel.username.isEmpty ? "username" : viewModel.username)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.pitchBlack)
                                
                                let y = viewModel.yearsLifted
                                let m = viewModel.monthsLifted
                                let expStr = (!y.isEmpty && y != "0" ? "\(y)y " : "") + (!m.isEmpty && m != "0" ? "\(m)m " : "")
                                let finalExp = expStr.isEmpty ? "Just started" : expStr + "lifting"
                                let ageStr = viewModel.age.isEmpty ? "" : "\(viewModel.age)yo • "
                                
                                Text(ageStr + finalExp)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(Theme.pitchBlack)
                            }
                        }
                        
                        // Stats row
                        HStack(spacing: 12) {
                            // Height Pill
                            Button { initialStatSelection = .height; navToStats = true } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "ruler.fill")
                                        .foregroundColor(Theme.accent)
                                    Text("\(viewModel.height.isEmpty ? "--" : viewModel.height) \(viewModel.isHeightCm ? "cm" : "in")")
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
                                    Text("\(viewModel.weight.isEmpty ? "--" : viewModel.weight) \(viewModel.isWeightKg ? "kg" : "lbs")")
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
                                Text(viewModel.kudos.compactCount)
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
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    // Floats over the header instead of taking its own row
                    .overlay(alignment: .topTrailing) {
                        Menu {
                            Button(action: { showPhotoPicker = true }) {
                                Label("Change Profile Picture", systemImage: "person.crop.circle")
                            }
                            Button(role: .destructive, action: {
                                deletePassword = ""
                                showDeleteConfirm = true
                            }) {
                                Label("Delete Account", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Theme.textSecondary)
                                .padding(16)
                        }
                    }
                    .background(
                        Theme.paleSky.padding(.top, -1000)
                    )
                    
                    // BOTTOM HALF
                    VStack(spacing: 32) {
                        // Progress Flicker Gallery
                        let photoEntries = viewModel.progressEntries.sorted(by: { $0.date < $1.date }).filter { !$0.photoBase64.isEmpty }
                        ProgressFlickerGallery(photos: photoEntries.map(\.photoBase64),
                                               crop: ProgressCoverage.commonCrop(photoEntries.map(\.coverage)))
                        
                        // Lifts
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Proudest Lifts")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                            
                            if viewModel.proudestLifts.isEmpty {
                                Text("No lifts recorded yet.")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(Theme.textSecondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Theme.cardBackground)
                                    .cornerRadius(16)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.proudestLifts) { lift in
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
                        
                        // Goals
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Goals")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                            
                            if viewModel.goals.isEmpty {
                                Text("No goals set yet.")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(Theme.textSecondary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Theme.cardBackground)
                                    .cornerRadius(16)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.goals, id: \.self) { goal in
                                        HStack(spacing: 16) {
                                            Image(systemName: "target")
                                                .foregroundColor(Theme.accent)
                                            Text(goal)
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                                .foregroundColor(Theme.textPrimary)
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Theme.cardBackground)
                                        .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        
                        #if DEBUG
                        Button(action: {
                            Task {
                                guard let uid = Auth.auth().currentUser?.uid else { return }
                                let db = Firestore.firestore()
                                if let snapshot = try? await db.collection("users").document(uid).collection("progress").getDocuments() {
                                    for doc in snapshot.documents {
                                        try? await doc.reference.delete()
                                    }
                                }
                                await MainActor.run { viewModel.progressEntries = [] }
                            }
                        }) {
                            Text("Wipe All Progress (Dev)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Theme.cardBackground)
                                .cornerRadius(16)
                        }
                        #endif

                        Button(action: {
                            do {
                                try FirebaseAuth.Auth.auth().signOut()
                            } catch {}
                        }) {
                            Text("Log Out")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.red)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Theme.cardBackground)
                                .cornerRadius(16)
                        }
                        .padding(.top, 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
        .overlay {
                if isDeletingAccount {
                    ZStack {
                        Color.black.opacity(0.6).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                                .scaleEffect(1.5)
                            Text("Deleting account…")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        .alert("Delete Account?", isPresented: $showDeleteConfirm) {
                SecureField("Password", text: $deletePassword)
                Button("Cancel", role: .cancel) { deletePassword = "" }
                Button("Delete", role: .destructive) {
                    let password = deletePassword
                    deletePassword = ""
                    isDeletingAccount = true
                    Task {
                        do {
                            // On success Auth signs out and OnboardingWrapperView returns to onboarding
                            try await viewModel.deleteAccount(password: password)
                        } catch let error as NSError where error.domain == "PumpCheck" {
                            deleteError = error.localizedDescription
                        } catch {
                            deleteError = "Something went wrong while deleting your account. Check your connection and try again."
                        }
                        isDeletingAccount = false
                    }
                }
                .disabled(deletePassword.isEmpty)
            } message: {
                Text("This permanently deletes your account, posts, comments, kudos and progress photos. This can't be undone. Enter your password to confirm.")
            }
        .alert("Couldn't Delete Account", isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteError ?? "")
            }
        // No title on the profile, so don't reserve space for a navigation bar
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPhotoPicker) {
            ProfilePhotoPicker(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $navToStats) {
                StatsView(userId: Auth.auth().currentUser?.uid ?? "", username: viewModel.username, heightStr: viewModel.height, weightStr: viewModel.weight, lifts: viewModel.proudestLifts,
                          onAddWeight: { weight, date in try await viewModel.addWeightEntry(weight: weight, date: date) },
                          weightUnit: viewModel.isWeightKg ? "kg" : "lbs",
                          selection: initialStatSelection)
            }
        }
    }
}
}

struct ProgressFlickerGallery: View {
    let photos: [String] // Array of base64 strings
    var crop: ProgressCrop = .full // Shared crop that hides black borders, see ProgressCoverage
    @State private var sliderValue: Double = 0
    @AppStorage(ProgressSliderMode.storageKey) private var sliderMode: ProgressSliderMode = .flicker
    
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
                    ProgressPhotoStack(photos: photos, sliderValue: sliderValue, mode: sliderMode, crop: crop)
                        .overlay(alignment: .topTrailing) {
                            if photos.count > 1 {
                                ProgressSliderModeToggle(mode: $sliderMode)
                            }
                        }

                    if photos.count > 1 {
                        VStack(spacing: 4) {
                            Slider(value: $sliderValue, in: 0...Double(photos.count - 1), onEditingChanged: { editing in
                                if !editing && sliderMode == .flicker {
                                    sliderValue = round(sliderValue)
                                }
                            })
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
                .background(Theme.pitchBlack.opacity(0.2))
                .cornerRadius(16)
            }
        }
    }
}
