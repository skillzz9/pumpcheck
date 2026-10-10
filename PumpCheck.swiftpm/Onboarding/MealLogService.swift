import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Stores logged meals at users/{uid}/meals/{mealId}.
enum MealLogService {
    private static func mealsCollection() -> CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return Firestore.firestore().collection("users").document(uid).collection("meals")
    }

    static func save(_ meal: MealEntry) async throws {
        try await mealsCollection()?.document(meal.id).setData([
            "name": meal.name,
            "date": Timestamp(date: meal.time),
            "calories": meal.calories,
            "protein": meal.protein,
            "carbs": meal.carbs,
            "fat": meal.fat
        ])
    }

    static func delete(_ meal: MealEntry) async throws {
        try await mealsCollection()?.document(meal.id).delete()
    }

    /// Meals logged on the given day, oldest first.
    static func meals(on day: Date) async throws -> [MealEntry] {
        guard let collection = mealsCollection() else { return [] }
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!

        let snapshot = try await collection
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("date", isLessThan: Timestamp(date: end))
            .order(by: "date")
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let date = (data["date"] as? Timestamp)?.dateValue() else { return nil }
            return MealEntry(
                id: doc.documentID,
                name: data["name"] as? String ?? "Meal",
                time: date,
                calories: data["calories"] as? Int ?? 0,
                protein: data["protein"] as? Int ?? 0,
                carbs: data["carbs"] as? Int ?? 0,
                fat: data["fat"] as? Int ?? 0
            )
        }
    }
}
