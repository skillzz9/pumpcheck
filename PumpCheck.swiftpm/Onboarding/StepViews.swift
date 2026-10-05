import SwiftUI
import PhotosUI

struct UnitSwitcher: View {
    let option1: String
    let option2: String
    @Binding var isOption1: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Text(option1)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isOption1 ? Theme.paleSky : Theme.textSecondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
                .background(isOption1 ? Theme.accent : Color.clear)
                .clipShape(Capsule())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isOption1 = true
                    }
                }
            
            Text(option2)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(!isOption1 ? Theme.paleSky : Theme.textSecondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 16)
                .background(!isOption1 ? Theme.accent : Color.clear)
                .clipShape(Capsule())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isOption1 = false
                    }
                }
        }
        .background(Theme.cardBackground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
    }
}

enum UsernameStatus {
    case idle, checking, available
}

// Step 1: Account
struct Step1View: View {
    @Bindable var viewModel: OnboardingViewModel
    var onLoginTap: () -> Void
    
    @State private var showWelcome = false
    @State private var showInputs = false
    @State private var usernameStatus: UsernameStatus = .idle
    @State private var checkTask: Task<Void, Never>? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if showWelcome {
                Text("Welcome to Pump Check! Be proud of your progress")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                    .transition(.opacity)
            }
            
            if showInputs {
                Text("First, what should we call you?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .transition(.opacity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    TextField("Choose a username", text: $viewModel.username)
                        .textFieldStyle(PumpTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .onChange(of: viewModel.username) { oldValue, newValue in
                            checkTask?.cancel()
                            
                            if newValue.isEmpty {
                                withAnimation { usernameStatus = .idle }
                                return
                            }
                            
                            withAnimation { usernameStatus = .checking }
                            
                            checkTask = Task {
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                if !Task.isCancelled {
                                    withAnimation {
                                        usernameStatus = .available
                                    }
                                }
                            }
                        }
                    
                    if usernameStatus != .idle {
                        HStack(spacing: 6) {
                            if usernameStatus == .checking {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Checking availability...")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(Theme.textSecondary)
                            } else if usernameStatus == .available {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Available!")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.leading, 4)
                        .padding(.top, 2)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    Button(action: {
                        onLoginTap()
                    }) {
                        Text("Got an account? Login")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.accent)
                    }
                    .padding(.top, 4)
                }
                .transition(.opacity)
                
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .onAppear {
            if viewModel.hasSeenIntro {
                showWelcome = true
                showInputs = true
                
                if !viewModel.username.isEmpty {
                    usernameStatus = .available
                }
            } else {
                withAnimation(.easeIn(duration: 1.0)) {
                    showWelcome = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeIn(duration: 1.0)) {
                        showInputs = true
                        viewModel.hasSeenIntro = true
                    }
                }
            }
        }
    }
}

// Step 2: Body Metrics
struct Step2View: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hello \(viewModel.username.isEmpty ? "there" : viewModel.username),")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                Text("What are your stats?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Age")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                
                TextField("e.g. 25", text: $viewModel.age)
                    .keyboardType(.numberPad)
                    .textFieldStyle(PumpTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Height")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    UnitSwitcher(option1: "cm", option2: "in", isOption1: $viewModel.isHeightCm)
                }
                
                TextField(viewModel.isHeightCm ? "e.g. 180" : "e.g. 5'11", text: $viewModel.height)
                    .keyboardType(.numbersAndPunctuation)
                    .textFieldStyle(PumpTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Weight")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    UnitSwitcher(option1: "kg", option2: "lbs", isOption1: $viewModel.isWeightKg)
                }
                
                TextField(viewModel.isWeightKg ? "e.g. 80" : "e.g. 176", text: $viewModel.weight)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(PumpTextFieldStyle())
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// Step 3: Experience
struct Step3View: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Experience")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("How long have you lifted?")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                
                HStack(spacing: 16) {
                    TextField("Years", text: $viewModel.yearsLifted)
                        .keyboardType(.numberPad)
                        .textFieldStyle(PumpTextFieldStyle())
                    
                    TextField("Months", text: $viewModel.monthsLifted)
                        .keyboardType(.numberPad)
                        .textFieldStyle(PumpTextFieldStyle())
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Status")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                
                HStack {
                    Text("Natty")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Toggle("", isOn: $viewModel.isNatty)
                        .tint(Theme.accent)
                }
                .padding()
                .background(Theme.cardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.paleSky.opacity(0.05), lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// Step 4: Proudest Lifts
struct Step4View: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Proudest Lifts")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            
            VStack(spacing: 16) {
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.taupeGrey)
                    TextField("Search lift...", text: $viewModel.currentLiftName)
                        .onChange(of: viewModel.currentLiftName) { oldValue, newValue in
                            if newValue.isEmpty {
                                withAnimation {
                                    viewModel.isLiftSelected = false
                                }
                            }
                        }
                }
                .padding(16)
                .background(Theme.paleSky)
                .cornerRadius(16)
                .foregroundColor(Theme.pitchBlack)
                .environment(\.colorScheme, .light)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1)
                )
                
                // Autocomplete Suggestions
                if !viewModel.filteredLifts.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.filteredLifts, id: \.name) { lift in
                            Button(action: {
                                withAnimation {
                                    viewModel.selectLift(lift.name)
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                }
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: lift.icon)
                                        .foregroundColor(Theme.accent)
                                        .frame(width: 24)
                                    Text(lift.name)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                }
                                .padding()
                                .background(Theme.cardBackground)
                            }
                            Divider().background(Theme.taupeGrey.opacity(0.3))
                        }
                    }
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Detail Inputs
                if viewModel.isLiftSelected {
                    HStack(spacing: 16) {
                        TextField(viewModel.weightPlaceholderText, text: $viewModel.currentLiftWeight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(PumpTextFieldStyle())
                        
                        TextField("Reps", text: $viewModel.currentLiftReps)
                            .keyboardType(.numberPad)
                            .textFieldStyle(PumpTextFieldStyle())
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Button(action: {
                        withAnimation {
                            viewModel.addLift()
                        }
                    }) {
                        Text("Add Lift")
                            .pumpButtonStyle(isPrimary: false)
                    }
                    .transition(.opacity)
                }
            }
            
            if !viewModel.proudestLifts.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.proudestLifts) { lift in
                            HStack {
                                Text(lift.name)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text("\(lift.weight, specifier: "%.1f") × \(lift.reps)")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(Theme.accent)
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.top, 8)
                }
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }
}

// Step 5: Baseline Picture
struct Step5View: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Baseline Picture")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            
            PhotosPicker(selection: $viewModel.profileImageItem, matching: .images) {
                ZStack {
                    if let data = viewModel.profileImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Theme.accent.opacity(0.5), lineWidth: 2)
                            )
                            .transition(.opacity)
                    } else {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Theme.cardBackground)
                            .frame(height: 220)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Theme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                            )
                        
                        VStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Theme.accent)
                            Text("Tap to Upload")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .onChange(of: viewModel.profileImageItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        withAnimation {
                            viewModel.profileImageData = data
                            viewModel.hasSelectedPicture = true
                        }
                    }
                }
            }
            
            Text("Set your standard. Take this picture in your house or gym. Keep the location and lighting consistent every week for accurate AI progress tracking.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(Theme.textSecondary)
                .lineSpacing(6)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// Step 6: Goals
struct Step6View: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your Goals")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    TextField("What are your general goals?", text: $viewModel.currentGoal)
                        .textFieldStyle(PumpTextFieldStyle())
                        .submitLabel(.done)
                        .onSubmit {
                            withAnimation {
                                viewModel.addGoal()
                            }
                        }
                    
                    if !viewModel.currentGoal.isEmpty {
                        Button(action: {
                            withAnimation {
                                viewModel.addGoal()
                            }
                        }) {
                            Text("Add")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.paleSky)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 24)
                                .background(Theme.accent)
                                .cornerRadius(16)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            
            if !viewModel.goals.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.goals, id: \.self) { goal in
                            HStack(spacing: 16) {
                                Image(systemName: "target")
                                    .foregroundColor(Theme.accent)
                                    .font(.system(size: 20))
                                Text(goal)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                
                                Button(action: {
                                    withAnimation {
                                        viewModel.goals.removeAll(where: { $0 == goal })
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Theme.taupeGrey.opacity(0.6))
                                        .font(.system(size: 20))
                                }
                            }
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.top, 8)
                }
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }
}


// Step 7: Password
struct Step7View: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Secure your account")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    TextField("Enter your email", text: $viewModel.email)
                        .textFieldStyle(PumpTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    SecureField("Enter a secure password", text: $viewModel.password)
                        .textFieldStyle(PumpTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Re-enter Password")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)
                    SecureField("Confirm your password", text: $viewModel.confirmPassword)
                        .textFieldStyle(PumpTextFieldStyle())
                }
                
                if !viewModel.password.isEmpty && !viewModel.confirmPassword.isEmpty && viewModel.password != viewModel.confirmPassword {
                    Text("Passwords do not match")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}
