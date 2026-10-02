import SwiftUI

struct ProgressDetailView: View {
    let entry: ProgressEntry
    let isWeightKg: Bool
    var onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if let data = Data(base64Encoded: entry.photoBase64), let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 24)
                        }
                        
                        if !entry.weight.isEmpty {
                            HStack {
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(Theme.accent)
                                Text("\(entry.weight) \(isWeightKg ? "kg" : "lbs")")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Theme.cardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                        }
                        
                        let validLifts = entry.lifts.filter { $0.weight > 0 && $0.reps > 0 }
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
                                            Text("\(lift.weight, specifier: "%.1f") × \(lift.reps)")
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
            .navigationTitle(entry.date.formatted(date: .abbreviated, time: .omitted))
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
