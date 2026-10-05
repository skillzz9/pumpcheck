import SwiftUI
import FirebaseAuth
import Charts

struct ProfileView: View {
    var viewModel: OnboardingViewModel
    
    @State private var navToStats: Bool = false
    @State private var initialStatSelection: StatSelection = .height
    
    var body: some View {
        NavigationStack {
            ZStack {
            Theme.bgGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Profile Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Theme.cardBackground)
                                .frame(width: 140, height: 140)
                                .shadow(color: Theme.accent.opacity(0.2), radius: 20, x: 0, y: 10)
                            
                            if let data = viewModel.profileImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 140)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 140, height: 140)
                                    .foregroundColor(Theme.accent)
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
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(color: Theme.accent.opacity(0.3), radius: 3, x: 0, y: 2)
                                .offset(x: 45, y: -55)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text("@\(viewModel.username.isEmpty ? "username" : viewModel.username)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.pitchBlack)
                            
                            let y = viewModel.yearsLifted
                            let m = viewModel.monthsLifted
                            let expStr = (!y.isEmpty && y != "0" ? "\(y)y " : "") + (!m.isEmpty && m != "0" ? "\(m)m " : "")
                            let finalExp = expStr.isEmpty ? "Just started" : expStr + "lifting"
                            let ageStr = viewModel.age.isEmpty ? "" : "\(viewModel.age)yo • "
                            
                            Text(ageStr + finalExp)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.pitchBlack)
                        }
                        
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
                                Text("\(viewModel.kudos)")
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
                    .padding(.top, 40)
                    .padding(.bottom, 24)
                    .padding(.horizontal, 24)
                    .background(
                        Color.white
                        .padding(.top, -1000)
                        .padding(.horizontal, -24)
                    )
                    // Removed corner radius and offset padding so it acts as a sharp full-width block
                    
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
                    
                    // Progress Flicker Gallery
                    let photoArray = viewModel.progressEntries.sorted(by: { $0.date < $1.date }).map { $0.photoBase64 }.filter { !$0.isEmpty }
                    ProgressFlickerGallery(photos: photoArray)
                    
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
                    
                    Button(action: {
                        do {
                            try FirebaseAuth.Auth.auth().signOut()
                            // We need a way to reset the app state.
                            // The easiest way is to use a notification or binding, 
                            // but for this MVP we can just crash to restart or ideally set isCompleted = false
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
            .navigationDestination(isPresented: $navToStats) {
                StatsView(username: viewModel.username, heightStr: viewModel.height, weightStr: viewModel.weight, lifts: viewModel.proudestLifts, selection: initialStatSelection)
            }
        }
    }
}
}

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
