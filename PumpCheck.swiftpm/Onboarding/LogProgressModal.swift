import SwiftUI

struct LogProgressModal: View {
    @Bindable var viewModel: OnboardingViewModel
    let uiImage: UIImage
    var onSave: () -> Void
    var onCancel: () -> Void
    
    @State private var weight: String = ""
    @State private var newLifts: [LiftRecord] = []

    var weightPercentChange: Double? {
        let cleanOld = viewModel.weight.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNew = weight.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let oldW = Double(cleanOld),
              let newW = Double(cleanNew),
              oldW > 0 else { return nil }
        return ((newW - oldW) / oldW) * 100.0
    }

    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image Preview
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 2))
                            .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                            .padding(.top, 24)
                        
                        // Optional Weight
                        VStack(spacing: 8) {
                            HStack {
                                Text("Current Weight")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                
                                Spacer()
                                
                                if !viewModel.weight.isEmpty {
                                    Text(viewModel.weight)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)
                                    
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(Theme.accent)
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.horizontal, 4)
                                }
                                
                                TextField("New", text: $weight)
                                    .keyboardType(.decimalPad)
                                    .padding(12)
                                    .frame(width: 80)
                                    .background(Theme.textBoxBlue)
                                    .cornerRadius(12)
                                    .foregroundColor(Theme.textPrimary)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1))
                                
                                Text(viewModel.isWeightKg ? "kg" : "lbs")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textSecondary)
                                    .padding(.leading, 4)
                            }
                            
                            if let inc = weightPercentChange {
                                HStack {
                                    Image(systemName: inc >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    Text(String(format: "%.1f%% %@", abs(inc), inc >= 0 ? "increase" : "decrease"))
                                }
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(inc >= 0 ? .green : .red)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        
                        // Lifts
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Update Lifts")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal, 24)
                            
                            ForEach($newLifts) { $lift in
                                LiftUpdateRow(lift: $lift, oldLifts: viewModel.proudestLifts)
                            }
                            
                            Button(action: {
                                newLifts.append(LiftRecord(name: "", weight: 0, reps: 0))
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Another Lift")
                                }
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.accent)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Theme.textBoxBlue)
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Log Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancel() }
                        .foregroundColor(Theme.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveProgress() }
                        .fontWeight(.bold)
                        .foregroundColor(Theme.accent)
                }
            }
            .onAppear {
                // Initialize with established lifts
                newLifts = viewModel.proudestLifts
                // If they have no established lifts, start with one empty one
                if newLifts.isEmpty {
                    newLifts.append(LiftRecord(name: "", weight: 0, reps: 0))
                }
            }
        }
    }
    
    func saveProgress() {
        guard let data = uiImage.jpegData(compressionQuality: 0.1) else { return }
        let base64 = data.base64EncodedString()
        
        let entry = ProgressEntry(
            id: UUID().uuidString,
            date: Date(),
            photoBase64: base64,
            weight: weight,
            lifts: newLifts
        )
        viewModel.saveProgressEntry(entry)
        
        // Update main profile stats
        var didUpdateStats = false
        if !weight.isEmpty && viewModel.weight != weight {
            viewModel.weight = weight
            didUpdateStats = true
        }
        for newLift in newLifts where newLift.weight > 0 && newLift.reps > 0 && !newLift.name.isEmpty {
            if let index = viewModel.proudestLifts.firstIndex(where: { $0.name.lowercased() == newLift.name.lowercased() }) {
                if viewModel.proudestLifts[index].weight != newLift.weight || viewModel.proudestLifts[index].reps != newLift.reps {
                    viewModel.proudestLifts[index] = newLift
                    didUpdateStats = true
                }
            } else {
                viewModel.proudestLifts.append(newLift)
                didUpdateStats = true
            }
        }
        
        if didUpdateStats {
            viewModel.syncProfileStatsToFirebase()
        }
        
        onSave()
    }
}

struct LiftUpdateRow: View {
    @Binding var lift: LiftRecord
    let oldLifts: [LiftRecord]
    
    // Create temporary string states for the TextFields to handle decimals properly
    @State private var weightStr: String = ""
    @State private var repsStr: String = ""
    
    var oldLift: LiftRecord? {
        oldLifts.first(where: { $0.name.lowercased() == lift.name.lowercased() })
    }
    
    var percentIncrease: Double? {
        guard let old = oldLift, old.weight > 0, old.reps > 0 else { return nil }
        guard lift.weight > 0, lift.reps > 0 else { return nil }
        
        // Use Epley formula for 1 Rep Max estimation: 1RM = W * (1 + R/30)
        let old1RM = old.weight * (1.0 + Double(old.reps) / 30.0)
        let new1RM = lift.weight * (1.0 + Double(lift.reps) / 30.0)
        
        return ((new1RM - old1RM) / old1RM) * 100.0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Lift Name (e.g. Bench Press)", text: $lift.name)
                .textFieldStyle(PumpTextFieldStyle())
            
            VStack(spacing: 8) {
                // Weight Row
                HStack {
                    Text("Weight")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 60, alignment: .leading)
                    
                    Spacer()
                    
                    if let old = oldLift {
                        Text(old.weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", old.weight) : String(format: "%.1f", old.weight))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(Theme.accent)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 4)
                    }
                    
                    TextField("New", text: $weightStr)
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .frame(width: 80)
                        .background(Theme.textBoxBlue)
                        .cornerRadius(12)
                        .foregroundColor(Theme.textPrimary)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1))
                        .onChange(of: weightStr) { _, newValue in
                            lift.weight = Double(newValue) ?? 0
                        }
                }
                
                // Reps Row
                HStack {
                    Text("Reps")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 60, alignment: .leading)
                    
                    Spacer()
                    
                    if let old = oldLift {
                        Text("\(old.reps)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(Theme.accent)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 4)
                    }
                    
                    TextField("New", text: $repsStr)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .frame(width: 80)
                        .background(Theme.textBoxBlue)
                        .cornerRadius(12)
                        .foregroundColor(Theme.textPrimary)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1))
                        .onChange(of: repsStr) { _, newValue in
                            lift.reps = Int(newValue) ?? 0
                        }
                }
            }
            
            if let inc = percentIncrease {
                HStack {
                    Image(systemName: inc >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(String(format: "%.1f%% %@", abs(inc), inc >= 0 ? "increase" : "decrease"))
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(inc >= 0 ? .green : .red)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal, 24)
        .onAppear {
            weightStr = lift.weight > 0 ? (lift.weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", lift.weight) : String(lift.weight)) : ""
            repsStr = lift.reps > 0 ? String(lift.reps) : ""
        }
    }
}
