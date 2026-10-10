import Foundation
import FirebaseAuth
import FirebaseFirestore

/// One day's intake, kept up to date as meals are logged.
struct DailySummary: Identifiable {
    var id: String { dateKey }
    let dateKey: String
    let date: Date
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let calorieGoal: Int
    let dietGoal: String
    let mealCount: Int

    var isLogged: Bool { mealCount > 0 }

    /// Lose: at or under the goal. Gain: at or over it. Maintain: within 10%.
    var isOnTarget: Bool {
        guard isLogged, calorieGoal > 0 else { return false }
        switch DietGoal(rawValue: dietGoal) {
        case .lose: return calories <= calorieGoal
        case .gain: return calories >= calorieGoal
        default: return abs(calories - calorieGoal) <= calorieGoal / 10
        }
    }
}

/// Stores daily totals at users/{uid}/dailyCalories/{yyyy-MM-dd}, keyed by the user's local date.
enum DailyCalorieService {
    /// Built per call so it always uses the user's current time zone.
    private static func keyFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    static func dateKey(for date: Date) -> String {
        keyFormatter().string(from: date)
    }

    private static func collection() -> CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return Firestore.firestore().collection("users").document(uid).collection("dailyCalories")
    }

    /// Overwrites the day's totals from its full list of meals.
    static func save(day: Date, meals: [MealEntry], calorieGoal: Int, dietGoal: String) async throws {
        try await collection()?.document(dateKey(for: day)).setData([
            "date": dateKey(for: day),
            "calories": meals.reduce(0) { $0 + $1.calories },
            "protein": meals.reduce(0) { $0 + $1.protein },
            "carbs": meals.reduce(0) { $0 + $1.carbs },
            "fat": meals.reduce(0) { $0 + $1.fat },
            "calorieGoal": calorieGoal,
            "dietGoal": dietGoal,
            "mealCount": meals.count,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    /// The most recent days with a summary, newest first.
    static func recent(limit: Int = 400) async throws -> [DailySummary] {
        guard let collection = collection() else { return [] }
        let snapshot = try await collection.order(by: "date", descending: true).limit(to: limit).getDocuments()
        let formatter = keyFormatter()
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let key = data["date"] as? String, let date = formatter.date(from: key) else { return nil }
            return DailySummary(
                dateKey: key,
                date: date,
                calories: data["calories"] as? Int ?? 0,
                protein: data["protein"] as? Int ?? 0,
                carbs: data["carbs"] as? Int ?? 0,
                fat: data["fat"] as? Int ?? 0,
                calorieGoal: data["calorieGoal"] as? Int ?? 0,
                dietGoal: data["dietGoal"] as? String ?? "",
                mealCount: data["mealCount"] as? Int ?? 0
            )
        }
    }

    /// Consecutive logged days ending today, or yesterday if today isn't logged yet.
    static func currentStreak(_ summaries: [DailySummary]) -> Int {
        let logged = Set(summaries.filter(\.isLogged).map(\.dateKey))
        let calendar = Calendar.current
        var day = Date.now
        if !logged.contains(dateKey(for: day)) {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        var streak = 0
        while logged.contains(dateKey(for: day)) {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    static func bestStreak(_ summaries: [DailySummary]) -> Int {
        let days = summaries.filter(\.isLogged).map { Calendar.current.startOfDay(for: $0.date) }.sorted()
        var best = 0, run = 0
        var previous: Date?
        for day in days {
            if let previous, Calendar.current.dateComponents([.day], from: previous, to: day).day == 1 {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }
        return best
    }
}
