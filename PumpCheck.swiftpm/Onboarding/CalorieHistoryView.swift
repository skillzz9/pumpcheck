import SwiftUI
import Charts

/// Calories per day against the goal, plus streaks, to show consistency.
struct CalorieHistoryView: View {
    let summaries: [DailySummary]
    let currentGoal: Int

    @Environment(\.dismiss) private var dismiss
    @State private var range = 7

    private var startDate: Date {
        Calendar.current.date(byAdding: .day, value: -(range - 1), to: Calendar.current.startOfDay(for: .now))!
    }

    private var inRange: [DailySummary] {
        summaries.filter { $0.isLogged && $0.date >= startDate }.sorted { $0.date < $1.date }
    }

    private var averageCalories: Int {
        inRange.isEmpty ? 0 : inRange.reduce(0) { $0 + $1.calories } / inRange.count
    }

    var body: some View {
        ZStack {
            Theme.pitchBlack.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Calorie History")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(Theme.cardBackground)
                                .clipShape(Circle())
                        }
                    }

                    HStack(spacing: 12) {
                        statTile("\(DailyCalorieService.currentStreak(summaries))", "day streak", icon: "flame.fill")
                        statTile("\(DailyCalorieService.bestStreak(summaries))", "best streak", icon: "trophy.fill")
                    }

                    Picker("Range", selection: $range) {
                        Text("7 days").tag(7)
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                    }
                    .pickerStyle(.segmented)

                    chartCard

                    HStack(spacing: 12) {
                        statTile("\(averageCalories)", "avg kcal / day", icon: nil)
                        statTile("\(inRange.filter(\.isOnTarget).count)/\(inRange.count)", "days on target", icon: nil)
                    }
                }
                .padding(24)
            }
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if inRange.isEmpty {
                Text("No days logged in this range yet.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart {
                    ForEach(inRange) { day in
                        BarMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Calories", day.calories)
                        )
                        .foregroundStyle(day.isOnTarget ? Theme.accent : Theme.overLimit)
                        .cornerRadius(4)
                    }

                    if currentGoal > 0 {
                        RuleMark(y: .value("Goal", currentGoal))
                            .foregroundStyle(Theme.taupeGrey.opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .annotation(position: .top, alignment: .leading) {
                                Text("Goal \(currentGoal)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(Theme.textSecondary)
                            }
                    }
                }
                .chartXScale(domain: startDate...Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now))!)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: range == 7 ? 1 : (range == 30 ? 7 : 30))) { _ in
                        AxisGridLine().foregroundStyle(Theme.taupeGrey.opacity(0.15))
                        AxisValueLabel(format: range == 7 ? .dateTime.weekday(.abbreviated) : .dateTime.day().month(.abbreviated))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine().foregroundStyle(Theme.taupeGrey.opacity(0.15))
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(height: 220)

                HStack(spacing: 16) {
                    legendDot(Theme.accent, "On target")
                    legendDot(Theme.overLimit, "Off target")
                }
            }
        }
        .padding(20)
        .background(Theme.cardBackground)
        .cornerRadius(20)
    }

    private func statTile(_ value: String, _ label: String, icon: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.accent)
                }
                Text(value)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .monospacedDigit()
            }
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textSecondary)
        }
    }
}
