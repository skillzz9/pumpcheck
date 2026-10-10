import SwiftUI
import Charts
import FirebaseFirestore

enum StatSelection: Equatable, Hashable {
    case height
    case weight
    case lift(String)
}

struct StatsView: View {
    let userId: String
    let username: String
    let heightStr: String
    let weightStr: String
    let lifts: [LiftRecord]
    
    @State var selection: StatSelection
    @State private var progressEntries: [ProgressEntry] = []
    @State private var isFetching: Bool = true
    
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
                    if isFetching {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                            .frame(height: 350)
                            .frame(maxWidth: .infinity)
                    } else {
                        if selection == .height {
                            StatChartView(title: "Height", data: getFakeHeightData())
                        } else if selection == .weight {
                            StatChartView(title: "Weight", data: getRealWeightData())
                        } else if case let .lift(name) = selection {
                            StatChartView(title: "\(name) Progress", data: getRealLiftData(for: name))
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                
                Spacer()
            }
        }
        .navigationTitle("\(username)'s Stats")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchProgress()
        }
    }
    
    private func fetchProgress() async {
        let db = Firestore.firestore()
        do {
            let snap = try await db.collection("users").document(userId).collection("progress").getDocuments()
            var entries: [ProgressEntry] = []
            for doc in snap.documents {
                let data = doc.data()
                let ts = data["date"] as? Timestamp
                let d = ts?.dateValue() ?? Date()
                let w = data["weight"] as? String ?? ""
                let p = data["photoBase64"] as? String ?? ""
                var parsedLifts: [LiftRecord] = []
                if let rawLifts = data["lifts"] as? [[String: Any]] {
                    parsedLifts = rawLifts.compactMap { ld -> LiftRecord? in
                        guard let ln = ld["name"] as? String, let lw = ld["weight"] as? Double else { return nil }
                        let lr = ld["reps"] as? Int ?? 1
                        return LiftRecord(name: ln, weight: lw, reps: lr)
                    }
                }
                entries.append(ProgressEntry(id: doc.documentID, date: d, photoBase64: p, weight: w, lifts: parsedLifts))
            }
            await MainActor.run {
                self.progressEntries = entries.sorted(by: { $0.date < $1.date })
                self.isFetching = false
            }
        } catch {
            await MainActor.run { self.isFetching = false }
        }
    }

    private func getFakeHeightData() -> [ChartDataPoint] {
        let h = Double(heightStr) ?? 170.0
        if progressEntries.isEmpty {
            return [ChartDataPoint(date: Date(), value: h)]
        }
        return progressEntries.map { ChartDataPoint(date: $0.date, value: h) }
    }
    
    private func getRealWeightData() -> [ChartDataPoint] {
        let currentWeight = Double(weightStr) ?? 75.0
        let pts = progressEntries.compactMap { entry -> ChartDataPoint? in
            if let w = Double(entry.weight) {
                return ChartDataPoint(date: entry.date, value: w)
            }
            return nil
        }
        if pts.isEmpty {
            return [ChartDataPoint(date: Date(), value: currentWeight)]
        }
        return pts
    }
    
    private func getRealLiftData(for name: String) -> [ChartDataPoint] {
        let pts = progressEntries.compactMap { entry -> ChartDataPoint? in
            if let l = entry.lifts.first(where: { $0.name == name }) {
                return ChartDataPoint(date: entry.date, value: l.weight)
            }
            return nil
        }
        if pts.isEmpty {
            if let lift = lifts.first(where: { $0.name == name }) {
                return [ChartDataPoint(date: Date(), value: lift.weight)]
            }
            return []
        }
        return pts
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

    /// At least a week wide, so a few entries don't get squeezed into a sliver of time.
    private var xDomain: ClosedRange<Date> {
        let calendar = Calendar.current
        let dates = data.map(\.date)
        let start = calendar.startOfDay(for: dates.min() ?? .now)
        let last = calendar.startOfDay(for: dates.max() ?? .now)
        let end = max(last, calendar.date(byAdding: .day, value: 6, to: start)!)
        return start...calendar.date(byAdding: .day, value: 1, to: end)!
    }

    /// Fits the data with some headroom instead of starting at 0, so changes are visible.
    private var yDomain: ClosedRange<Double> {
        let values = data.map(\.value)
        let low = values.min() ?? 0, high = values.max() ?? 1
        let padding = max((high - low) * 0.15, 2)
        return max(low - padding, 0)...(high + padding)
    }

    /// Label format that matches the span: days, then months, then months with years.
    private var xLabelFormat: Date.FormatStyle {
        let days = xDomain.upperBound.timeIntervalSince(xDomain.lowerBound) / 86_400
        if days <= 60 { return .dateTime.day().month(.abbreviated) }
        if days <= 730 { return .dateTime.month(.abbreviated) }
        return .dateTime.month(.abbreviated).year(.twoDigits)
    }
    
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
                .interpolationMethod(.monotone)
                
                AreaMark(
                    x: .value("Date", point.date),
                    yStart: .value("Floor", yDomain.lowerBound),
                    yEnd: .value("Value", point.value)
                )
                .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                .interpolationMethod(.monotone)
                
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
            .chartXScale(domain: xDomain)
            .chartYScale(domain: yDomain)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) {
                    AxisGridLine().foregroundStyle(Theme.taupeGrey.opacity(0.2))
                    AxisValueLabel(format: xLabelFormat, collisionResolution: .greedy)
                        .foregroundStyle(Theme.textSecondary)
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
