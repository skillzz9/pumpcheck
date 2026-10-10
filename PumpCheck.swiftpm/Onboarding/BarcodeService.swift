import Foundation

/// A packaged product found by barcode, with macros per 100 g.
struct BarcodeProduct {
    let barcode: String
    let name: String
    let brand: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    /// Grams in one serving from the label, when the database has it.
    let servingGrams: Double?
    let servingLabel: String?
}

/// Looks barcodes up in Open Food Facts (international) first, then USDA branded foods (mostly US).
enum BarcodeService {
    static func lookup(_ barcode: String) async throws -> BarcodeProduct? {
        let code = barcode.filter(\.isNumber)
        guard !code.isEmpty else { return nil }

        var networkError: Error?
        var anyAnswered = false
        do {
            if let product = try await openFoodFacts(code) { return product }
            anyAnswered = true
        } catch {
            networkError = error
        }
        do {
            if let product = try await usdaBranded(code) { return product }
            anyAnswered = true
        } catch {
            networkError = networkError ?? error
        }
        // Only report "not found" if at least one database actually answered
        if !anyAnswered, let networkError { throw networkError }
        return nil
    }

    private static func number(_ value: Any?) -> Double? {
        if let number = value as? NSNumber { return number.doubleValue }
        if let string = value as? String { return Double(string) }
        return nil
    }

    private static func openFoodFacts(_ code: String) async throws -> BarcodeProduct? {
        let fields = "product_name,brands,serving_size,serving_quantity,nutriments"
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(code).json?fields=\(fields)") else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        // Open Food Facts asks apps to identify themselves
        request.setValue("PumpCheck/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              (json["status"] as? Int) == 1,
              let product = json["product"] as? [String: Any],
              let nutriments = product["nutriments"] as? [String: Any],
              let calories = number(nutriments["energy-kcal_100g"]) else { return nil }

        let name = (product["product_name"] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
        return BarcodeProduct(
            barcode: code,
            name: name.isEmpty ? "Scanned product" : name,
            brand: (product["brands"] as? String)?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? "",
            calories: calories,
            protein: number(nutriments["proteins_100g"]) ?? 0,
            carbs: number(nutriments["carbohydrates_100g"]) ?? 0,
            fat: number(nutriments["fat_100g"]) ?? 0,
            servingGrams: number(product["serving_quantity"]).flatMap { $0 > 0 ? $0 : nil },
            servingLabel: product["serving_size"] as? String
        )
    }

    private static func usdaBranded(_ code: String) async throws -> BarcodeProduct? {
        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        components.queryItems = [URLQueryItem(name: "api_key", value: Secrets.usdaAPIKey)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["query": code, "dataType": ["Branded"], "pageSize": 5])

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let foods = json["foods"] as? [[String: Any]] else { return nil }

        // Search is fuzzy, so require the barcode itself to match (ignoring leading zeros)
        func normalized(_ value: String) -> Substring { value.drop { $0 == "0" } }
        guard let food = foods.first(where: { normalized(($0["gtinUpc"] as? String) ?? "") == normalized(code) }),
              let nutrients = food["foodNutrients"] as? [[String: Any]] else { return nil }

        var values: [Int: Double] = [:]
        for nutrient in nutrients {
            if let id = nutrient["nutrientId"] as? Int, let value = number(nutrient["value"]) { values[id] = value }
        }
        guard let calories = values[1008] ?? values[2047] ?? values[2048] else { return nil }

        let unit = (food["servingSizeUnit"] as? String)?.uppercased()
        let servingGrams = ["G", "GRM", "ML", "MLT"].contains(unit ?? "") ? number(food["servingSize"]) : nil
        return BarcodeProduct(
            barcode: code,
            name: (food["description"] as? String)?.capitalized ?? "Scanned product",
            brand: (food["brandName"] as? String ?? food["brandOwner"] as? String ?? "").capitalized,
            calories: calories,
            protein: values[1003] ?? 0,
            carbs: values[1005] ?? 0,
            fat: values[1004] ?? 0,
            servingGrams: servingGrams,
            servingLabel: food["householdServingFullText"] as? String
        )
    }
}
