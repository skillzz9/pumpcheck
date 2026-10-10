import os
import re

# Fix ProfileView.swift
profile_path = "PumpCheck.swiftpm/Onboarding/ProfileView.swift"
with open(profile_path, "r") as f:
    profile = f.read()

profile_new = re.sub(
    r"ScrollView \{[\s\S]*\}\s*\.navigationDestination",
    r"""ScrollView {
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
                                            .stroke(Theme.paleSky, lineWidth: 2)
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
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 24)
                    .background(
                        Theme.paleSky.padding(.top, -1000)
                    )
                    
                    // BOTTOM HALF
                    VStack(spacing: 32) {
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
            .navigationDestination""",
    profile
)

with open(profile_path, "w") as f:
    f.write(profile_new)


# Fix PublicProfileView.swift
public_path = "PumpCheck.swiftpm/Onboarding/PublicProfileView.swift"
with open(public_path, "r") as f:
    public_profile = f.read()

public_profile_new = re.sub(
    r"ScrollView \{[\s\S]*\}\s*\.navigationTitle",
    r"""ScrollView {
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
        .navigationTitle""",
    public_profile
)

with open(public_path, "w") as f:
    f.write(public_profile_new)

