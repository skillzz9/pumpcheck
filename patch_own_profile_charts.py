import re

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content = f.read()

content = content.replace("import FirebaseAuth", "import FirebaseAuth\nimport Charts")

target_state = """    var body: some View {"""
replacement_state = """    @State private var showHeightChart = false
    @State private var showWeightChart = false
    @State private var selectedLiftChartName: String? = nil
    
    var body: some View {"""
if "showHeightChart" not in content:
    content = content.replace(target_state, replacement_state)

target_height_pill = """                            // Height Pill
                            HStack(spacing: 6) {
                                Image(systemName: "ruler.fill")
                                    .foregroundColor(Theme.accent)
                                Text("\\(viewModel.height.isEmpty ? "--" : viewModel.height) \\(viewModel.isHeightCm ? "cm" : "in")")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Theme.cardBackground)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.taupeGrey.opacity(0.2), lineWidth: 1))"""

replacement_height_pill = """                            // Height Pill
                            Button { showHeightChart = true } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "ruler.fill")
                                        .foregroundColor(Theme.accent)
                                    Text("\\(viewModel.height.isEmpty ? "--" : viewModel.height) \\(viewModel.isHeightCm ? "cm" : "in")")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)
                                }
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Theme.cardBackground)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Theme.taupeGrey.opacity(0.2), lineWidth: 1))
                            }"""
content = content.replace(target_height_pill, replacement_height_pill)

target_weight_pill = """                            // Weight Pill
                            HStack(spacing: 6) {
                                Image(systemName: "scalemass.fill")
                                    .foregroundColor(Theme.accent)
                                Text("\\(viewModel.weight.isEmpty ? "--" : viewModel.weight) \\(viewModel.isWeightKg ? "kg" : "lbs")")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Theme.cardBackground)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Theme.taupeGrey.opacity(0.2), lineWidth: 1))"""

replacement_weight_pill = """                            // Weight Pill
                            Button { showWeightChart = true } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "scalemass.fill")
                                        .foregroundColor(Theme.accent)
                                    Text("\\(viewModel.weight.isEmpty ? "--" : viewModel.weight) \\(viewModel.isWeightKg ? "kg" : "lbs")")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)
                                }
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Theme.cardBackground)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Theme.taupeGrey.opacity(0.2), lineWidth: 1))
                            }"""
content = content.replace(target_weight_pill, replacement_weight_pill)

target_lift = """                                    ForEach(viewModel.proudestLifts) { lift in
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
                                        .cornerRadius(16)
                                    }"""

replacement_lift = """                                    ForEach(viewModel.proudestLifts) { lift in
                                        Button { selectedLiftChartName = lift.name } label: {
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
                                            .cornerRadius(16)
                                        }
                                    }"""
content = content.replace(target_lift, replacement_lift)

target_end_body = """            }
        }
    }
}"""

replacement_end_body = """            }
        }
        .sheet(isPresented: $showHeightChart) {
            StatChartView(title: "Height Over Time", data: generateFakeData(baseValue: Double(viewModel.height) ?? 170.0, trend: 0.5))
        }
        .sheet(isPresented: $showWeightChart) {
            StatChartView(title: "Weight Over Time", data: generateFakeData(baseValue: Double(viewModel.weight) ?? 75.0, trend: 1.2))
        }
        .sheet(isPresented: Binding(get: { selectedLiftChartName != nil }, set: { if !$0 { selectedLiftChartName = nil } })) {
            if let name = selectedLiftChartName, let lift = viewModel.proudestLifts.first(where: { $0.name == name }) {
                StatChartView(title: "\\(name) Progress", data: generateFakeData(baseValue: lift.weight - 20, trend: 5.0, increaseOnly: true))
            }
        }
    }
    
    private func generateFakeData(baseValue: Double, trend: Double, increaseOnly: Bool = false) -> [ChartDataPoint] {
        var data: [ChartDataPoint] = []
        var current = baseValue
        let now = Date()
        
        for i in (0..<6).reversed() {
            let date = Calendar.current.date(byAdding: .month, value: -i, to: now)!
            data.append(ChartDataPoint(date: date, value: current))
            if increaseOnly {
                current += Double.random(in: 1.0...trend)
            } else {
                current += Double.random(in: -trend...trend)
            }
        }
        return data
    }
}"""
if "generateFakeData" not in content:
    content = content.replace(target_end_body, replacement_end_body)

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
    f.write(content)

print("Patched ProfileView successfully!")
