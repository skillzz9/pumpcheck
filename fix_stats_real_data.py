import sys

with open("PumpCheck.swiftpm/Onboarding/StatsView.swift", "r") as f:
    content = f.read()

# Replace getFakeHeightData
old_height = """    private func getFakeHeightData() -> [ChartDataPoint] {
        let h = Double(heightStr) ?? 170.0
        if progressEntries.isEmpty {
            return generateFakeData(baseValue: h, trend: 0.0)
        }
        return progressEntries.map { ChartDataPoint(date: $0.date, value: h) }
    }"""

new_height = """    private func getFakeHeightData() -> [ChartDataPoint] {
        let h = Double(heightStr) ?? 170.0
        if progressEntries.isEmpty {
            return [ChartDataPoint(date: Date(), value: h)]
        }
        return progressEntries.map { ChartDataPoint(date: $0.date, value: h) }
    }"""
content = content.replace(old_height, new_height)

# Replace getRealWeightData
old_weight = """    private func getRealWeightData() -> [ChartDataPoint] {
        if progressEntries.isEmpty {
            return generateFakeData(baseValue: Double(weightStr) ?? 75.0, trend: 1.2)
        }
        return progressEntries.compactMap { entry in
            if let w = Double(entry.weight) {
                return ChartDataPoint(date: entry.date, value: w)
            }
            return nil
        }
    }"""

new_weight = """    private func getRealWeightData() -> [ChartDataPoint] {
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
    }"""
content = content.replace(old_weight, new_weight)

# Replace getRealLiftData
old_lift = """    private func getRealLiftData(for name: String) -> [ChartDataPoint] {
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
    }"""

new_lift = """    private func getRealLiftData(for name: String) -> [ChartDataPoint] {
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
    }"""
content = content.replace(old_lift, new_lift)

with open("PumpCheck.swiftpm/Onboarding/StatsView.swift", "w") as f:
    f.write(content)

