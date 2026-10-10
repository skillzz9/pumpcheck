import sys

with open("PumpCheck.swiftpm/Onboarding/StatsView.swift", "r") as f:
    content = f.read()

# 1. Add Firebase import
content = content.replace("import Charts", "import Charts\nimport FirebaseFirestore")

# 2. Add userId and state
old_props = """    let username: String
    let heightStr: String
    let weightStr: String
    let lifts: [LiftRecord]
    
    @State var selection: StatSelection"""

new_props = """    let userId: String
    let username: String
    let heightStr: String
    let weightStr: String
    let lifts: [LiftRecord]
    
    @State var selection: StatSelection
    @State private var progressEntries: [ProgressEntry] = []
    @State private var isFetching: Bool = true"""
content = content.replace(old_props, new_props)


# 3. Replace the generation logic
old_gen = """                    if selection == .height {
                        StatChartView(title: "Height", data: generateFakeData(baseValue: Double(heightStr) ?? 170.0, trend: 0.5))
                    } else if selection == .weight {
                        StatChartView(title: "Weight", data: generateFakeData(baseValue: Double(weightStr) ?? 75.0, trend: 1.2))
                    } else if case let .lift(name) = selection, let lift = lifts.first(where: { $0.name == name }) {
                        StatChartView(title: "\(name) Progress", data: generateFakeData(baseValue: lift.weight - 20, trend: 5.0, increaseOnly: true))
                    }"""

new_gen = """                    if isFetching {
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
                    }"""
content = content.replace(old_gen, new_gen)


# 4. Add task and helper functions
old_bottom = """    private func generateFakeData(baseValue: Double, trend: Double, increaseOnly: Bool = false) -> [ChartDataPoint] {
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

new_bottom = """        .task {
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
                    parsedLifts = rawLifts.compactMap { ld in
                        guard let ln = ld["name"] as? String, let lw = ld["weight"] as? Double else { return nil }
                        return LiftRecord(name: ln, weight: lw)
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
            return generateFakeData(baseValue: h, trend: 0.0)
        }
        return progressEntries.map { ChartDataPoint(date: $0.date, value: h) }
    }
    
    private func getRealWeightData() -> [ChartDataPoint] {
        if progressEntries.isEmpty {
            return generateFakeData(baseValue: Double(weightStr) ?? 75.0, trend: 1.2)
        }
        return progressEntries.compactMap { entry in
            if let w = Double(entry.weight) {
                return ChartDataPoint(date: entry.date, value: w)
            }
            return nil
        }
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
                return generateFakeData(baseValue: lift.weight - 20, trend: 5.0, increaseOnly: true)
            }
            return []
        }
        return pts
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
content = content.replace(old_bottom, new_bottom)

with open("PumpCheck.swiftpm/Onboarding/StatsView.swift", "w") as f:
    f.write(content)
