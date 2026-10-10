import Foundation

/// A generic food from USDA FoodData Central, with macros per 100 g.
struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

actor USDAFoodService {
    static let shared = USDAFoodService()

    private var cache: [String: [USDAFood]] = [:]

    // FoodData Central nutrient IDs
    private static let energyIds = [1008, 2047, 2048] // kcal, then the Atwater variants some Foundation foods use
    private static let proteinId = 1003
    private static let carbsId = 1005
    private static let fatId = 1004

    /// Searches generic foods (not branded products), skipping entries without calorie data.
    func search(_ query: String) async throws -> [USDAFood] {
        let key = query.lowercased().trimmingCharacters(in: .whitespaces)
        if let cached = cache[key] { return cached }

        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        components.queryItems = [URLQueryItem(name: "api_key", value: Secrets.usdaAPIKey)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "query": query,
            "dataType": ["Foundation", "SR Legacy", "Survey (FNDDS)"],
            "pageSize": 8
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let foods = json["foods"] as? [[String: Any]] else {
            throw URLError(.badServerResponse)
        }

        let results: [USDAFood] = foods.compactMap { food in
            guard let fdcId = food["fdcId"] as? Int,
                  let description = food["description"] as? String,
                  let nutrients = food["foodNutrients"] as? [[String: Any]] else { return nil }

            var values: [Int: Double] = [:]
            for nutrient in nutrients {
                if let id = nutrient["nutrientId"] as? Int, let value = nutrient["value"] as? Double {
                    values[id] = value
                }
            }
            guard let calories = Self.energyIds.lazy.compactMap({ values[$0] }).first else { return nil }
            return USDAFood(
                fdcId: fdcId,
                description: description,
                calories: calories,
                protein: values[Self.proteinId] ?? 0,
                carbs: values[Self.carbsId] ?? 0,
                fat: values[Self.fatId] ?? 0
            )
        }

        cache[key] = results
        return results
    }
}
