import re

with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "r") as f:
    content = f.read()

content = content.replace("import FirebaseFirestore", "import FirebaseFirestore\nimport Charts")

target_state = """    @State private var isLoading = true"""
replacement_state = """    @State private var isLoading = true
    
    @State private var showHeightChart = false
    @State private var showWeightChart = false
    @State private var selectedLiftChartName: String? = nil"""
content = content.replace(target_state, replacement_state)

target_height_pill = """                            // Height Pill
                            HStack(spacing: 6) {
                                Image(systemName: "ruler.fill")
                                    .foregroundColor(Theme.accent)
                                Text("\\(height.isEmpty ? "--" : height) \\(isHeightCm ? "cm" : "in")")
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
                                    Text("\\(height.isEmpty ? "--" : height) \\(isHeightCm ? "cm" : "in")")
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
                                Text("\\(weight.isEmpty ? "--" : weight) \\(isWeightKg ? "kg" : "lbs")")
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
                                    Text("\\(weight.isEmpty ? "--" : weight) \\(isWeightKg ? "kg" : "lbs")")
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

target_lift = """                                    ForEach(proudestLifts) { lift in
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

replacement_lift = """                                    ForEach(proudestLifts) { lift in
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

target_end_body = """        .task {
            await fetchPublicProfile()
        }
    }"""

replacement_end_body = """        .task {
            await fetchPublicProfile()
        }
        .sheet(isPresented: $showHeightChart) {
            StatChartView(title: "Height Over Time", data: generateFakeData(baseValue: Double(height) ?? 170.0, trend: 0.5))
        }
        .sheet(isPresented: $showWeightChart) {
            StatChartView(title: "Weight Over Time", data: generateFakeData(baseValue: Double(weight) ?? 75.0, trend: 1.2))
        }
        .sheet(isPresented: Binding(get: { selectedLiftChartName != nil }, set: { if !$0 { selectedLiftChartName = nil } })) {
            if let name = selectedLiftChartName, let lift = proudestLifts.first(where: { $0.name == name }) {
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
    }"""
content = content.replace(target_end_body, replacement_end_body)

structs = """
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct StatChartView: View {
    let title: String
    let data: [ChartDataPoint]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.pitchBlack.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Chart(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(Theme.accent.gradient)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                        
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(Theme.accent)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) {
                            AxisGridLine().foregroundStyle(Theme.taupeGrey.opacity(0.2))
                            AxisValueLabel().foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) {
                            AxisGridLine().foregroundStyle(Theme.taupeGrey.opacity(0.2))
                            AxisValueLabel(format: .dateTime.month().year()).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .frame(height: 300)
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.fraction(0.6)])
    }
}
"""
content += structs

with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "w") as f:
    f.write(content)

print("Patched PublicProfileView successfully!")
