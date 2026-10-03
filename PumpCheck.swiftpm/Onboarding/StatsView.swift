import SwiftUI
import Charts

enum StatSelection: Equatable, Hashable {
    case height
    case weight
    case lift(String)
}

struct StatsView: View {
    let username: String
    let heightStr: String
    let weightStr: String
    let lifts: [LiftRecord]
    
    @State var selection: StatSelection
    
    var body: some View {
        ZStack {
            Theme.pitchBlack.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Selector Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Height Pill
                        Button {
                            withAnimation { selection = .height }
                        } label: {
                            Image(systemName: "ruler.fill")
                                .font(.system(size: 20))
                                .foregroundColor(selection == .height ? Theme.pitchBlack : Theme.textPrimary)
                                .padding()
                                .background(selection == .height ? Theme.accent : Theme.cardBackground)
                                .clipShape(Circle())
                        }
                        
                        // Weight Pill
                        Button {
                            withAnimation { selection = .weight }
                        } label: {
                            Image(systemName: "scalemass.fill")
                                .font(.system(size: 20))
                                .foregroundColor(selection == .weight ? Theme.pitchBlack : Theme.textPrimary)
                                .padding()
                                .background(selection == .weight ? Theme.accent : Theme.cardBackground)
                                .clipShape(Circle())
                        }
                        
                        // Lift Pills
                        ForEach(lifts) { lift in
                            Button {
                                withAnimation { selection = .lift(lift.name) }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                        .font(.system(size: 16))
                                    Text(lift.name)
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(selection == .lift(lift.name) ? Theme.pitchBlack : Theme.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(selection == .lift(lift.name) ? Theme.accent : Theme.cardBackground)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 16)
                
                // Chart Area
                VStack {
                    if selection == .height {
                        StatChartView(title: "Height", data: generateFakeData(baseValue: Double(heightStr) ?? 170.0, trend: 0.5))
                    } else if selection == .weight {
                        StatChartView(title: "Weight", data: generateFakeData(baseValue: Double(weightStr) ?? 75.0, trend: 1.2))
                    } else if case let .lift(name) = selection, let lift = lifts.first(where: { $0.name == name }) {
                        StatChartView(title: "\(name) Progress", data: generateFakeData(baseValue: lift.weight - 20, trend: 5.0, increaseOnly: true))
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                
                Spacer()
            }
        }
        .navigationTitle("\(username)'s Stats")
        .navigationBarTitleDisplayMode(.inline)
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
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct StatChartView: View {
    let title: String
    let data: [ChartDataPoint]
    
    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
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
            .frame(height: 350)
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal)
        }
        .padding(.top, 24)
    }
}
