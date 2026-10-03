with open("PumpCheck.swiftpm/Onboarding/ProgressDetailView.swift", "r") as f:
    content = f.read()

replacement = """import SwiftUI

struct ProgressDetailView: View {
    @State private var currentEntry: ProgressEntry
    let allEntries: [ProgressEntry]
    let isWeightKg: Bool
    var onDismiss: () -> Void
    
    init(initialEntry: ProgressEntry, allEntries: [ProgressEntry], isWeightKg: Bool, onDismiss: @escaping () -> Void) {
        self._currentEntry = State(initialValue: initialEntry)
        self.allEntries = allEntries
        self.isWeightKg = isWeightKg
        self.onDismiss = onDismiss
    }
    
    var currentIndex: Int {
        allEntries.firstIndex(where: { $0.id == currentEntry.id }) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Navigation Arrows
                        HStack {
                            Button(action: {
                                if currentIndex > 0 {
                                    currentEntry = allEntries[currentIndex - 1]
                                }
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(currentIndex > 0 ? Theme.accent : Color.gray.opacity(0.3))
                            }
                            .disabled(currentIndex == 0)
                            
                            Spacer()
                            
                            Button(action: {
                                if currentIndex < allEntries.count - 1 {
                                    currentEntry = allEntries[currentIndex + 1]
                                }
                            }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(currentIndex < allEntries.count - 1 ? Theme.accent : Color.gray.opacity(0.3))
                            }
                            .disabled(currentIndex >= allEntries.count - 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, -8) // Pull it slightly closer to the image
                        
                        if let data = Data(base64Encoded: currentEntry.photoBase64), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 24)
                        }
                        
                        if !currentEntry.weight.isEmpty {
                            HStack {
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(Theme.accent)
                                Text("\\(currentEntry.weight) \\(isWeightKg ? "kg" : "lbs")")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.cardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                        }
                        
                        let validLifts = currentEntry.lifts.filter { $0.weight > 0 && $0.reps > 0 }
                        if !validLifts.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Lifts Logged")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 12) {
                                    ForEach(validLifts) { lift in
                                        HStack {
                                            Text(lift.name)
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundColor(Theme.textPrimary)
                                            Spacer()
                                            Text("\\(lift.weight, specifier: "%.1f") × \\(lift.reps)")
                                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                                .foregroundColor(Theme.accent)
                                        }
                                        .padding()
                                        .background(Theme.cardBackground)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 24)
                }
            }
            .navigationTitle(currentEntry.date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Theme.accent)
                }
            }
        }
    }
}
"""

with open("PumpCheck.swiftpm/Onboarding/ProgressDetailView.swift", "w") as f:
    f.write(replacement)

print("Patched ProgressDetailView successfully!")
