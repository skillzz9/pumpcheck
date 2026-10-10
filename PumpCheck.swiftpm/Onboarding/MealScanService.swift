import Foundation
import UIKit

struct ScannedComponent: Codable {
    let name: String
    let quantity: Double
    let unit: String
    let grams: Double
    let usdaQuery: String
    let fromLabel: Bool
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

struct MealScanResult: Codable {
    let isFood: Bool
    let reasoning: String
    let name: String
    let components: [ScannedComponent]
}

/// Claude models the meal scan can run on, with first-party API prices per million tokens.
enum ScanModel: String, CaseIterable {
    case opus5 = "claude-opus-5"
    case sonnet5 = "claude-sonnet-5"
    case haiku45 = "claude-haiku-4-5"

    var displayName: String {
        switch self {
        case .opus5: return "Opus 5"
        case .sonnet5: return "Sonnet 5"
        case .haiku45: return "Haiku 4.5"
        }
    }

    var inputPrice: Double {
        switch self {
        case .opus5: return 5
        case .sonnet5: return 2
        case .haiku45: return 1
        }
    }

    var outputPrice: Double {
        switch self {
        case .opus5: return 25
        case .sonnet5: return 10
        case .haiku45: return 5
        }
    }

    /// Haiku 4.5 takes neither adaptive thinking nor effort.
    var supportsAdaptiveThinking: Bool { self != .haiku45 }
}

/// Token usage reported by the API for one request.
struct ScanUsage {
    var inputTokens = 0
    var outputTokens = 0

    func cost(on model: ScanModel) -> Double {
        (Double(inputTokens) * model.inputPrice + Double(outputTokens) * model.outputPrice) / 1_000_000
    }
}

class MealScanService {
    static let shared = MealScanService()

    /// Model for reading meal photos and descriptions.
    static let scanModel: ScanModel = .opus5
    /// Model for picking USDA entries from a short candidate list; a simple choice, so the cheapest model.
    static let matchModel: ScanModel = .haiku45

    private static let calibrationAnchors = """
    Calibration anchors: cooked rice 130 kcal/100g, cooked pasta 155 kcal/100g, cooked chicken breast 165 kcal/100g, bread 265 kcal/100g, cheese ~400 kcal/100g, oil 900 kcal/100g. A typical restaurant or home bowl of rice is 200-300g cooked.
    """

    private static let componentFields = """
    - name: short meal name, e.g. "Chicken Rice Bowl".
    - components: one entry per food, each with:
      - name: the food including its cooking method, e.g. "Pan-fried chicken thigh".
      - quantity: a number only, e.g. 250, 2, 1.5.
      - unit: e.g. "g", "ml", "eggs", "tbsp". Default to "g" for anything weighed.
      - grams: the weight in grams of this quantity (e.g. one large egg ~50, 1 tbsp oil ~14).
      - usdaQuery: 2-5 plain words to search the USDA FoodData Central database for this food in generic form, e.g. "chicken thigh fried", "rice white cooked", "olive oil".
      - fromLabel: true only if the values come from a visible nutrition label.
      - calories: integer kcal for this quantity.
      - protein, carbs, fat: integer grams for this quantity.
    """

    static let analyzePrompt = """
    You estimate calories and macros from food photos for the PumpCheck fitness app. Sizing the portions correctly is your main job; identifying the food is the easy part.

    Scale: a hand may be visible (an average adult palm is ~9cm wide); if so, it is your most reliable scale reference. Other references, most reliable first: utensils (fork ~19cm), plates (dinner ~27cm, side ~20cm), cans (12cm tall), standard bowls (a cereal bowl holds ~400ml when full).

    Sizing method:
    1. Identify each distinct food and its cooking method. Frying adds ~40-120 kcal per serving compared with grilling or boiling; assume oil was used unless the food is clearly steamed or raw.
    2. Judge the container's real size from a scale reference, then how full it is. Bowls hide volume: a bowl that looks half full often holds a full serving in its depth.
    3. Convert volume to weight by density: cooked rice, pasta and grains ~0.8g/ml, meat ~1g/ml, salad greens ~0.1g/ml, stews and curries ~0.9g/ml.
    4. \(calibrationAnchors)
    5. If packaging with a visible nutrition label is shown, use the label's values and the package size instead of estimating visually.
    6. People who don't track their food underestimate portions by ~30%. When torn between two sizes, pick the larger. Include cooking oil, butter, dressings and sauces as components when they're plausibly present.

    If the user describes the meal, trust their description over your visual read for what the food is and how it was cooked, and still size it from the photo.

    Fields:
    - isFood: false if the photo shows no food or drink; then return an empty components list.
    - reasoning: 1-2 sentences on the scale reference you used and the container's estimated size and fullness. Write this before any numbers.
    \(componentFields)
    """

    static let fixPrompt = """
    You previously estimated the calories and macros for this food photo, and the user is correcting your estimate. They ate the meal, so trust their correction over your visual read.

    Rules:
    1. Apply the correction fully. If a portion was bigger or smaller, scale that component's quantity and all its macros proportionally. If a food was misidentified, use the correct food's nutrition values.
    2. Leave components the user did not mention unchanged, unless the correction logically affects them.
    3. \(calibrationAnchors)

    Fields:
    - isFood: true.
    - reasoning: 1-2 sentences on how you applied the correction.
    \(componentFields)
    """

    // Field order matters: the model reasons about scale before it commits to numbers.
    private static let outputSchema: [String: Any] = [
        "type": "object",
        "additionalProperties": false,
        "required": ["isFood", "reasoning", "name", "components"],
        "properties": [
            "isFood": ["type": "boolean"],
            "reasoning": ["type": "string"],
            "name": ["type": "string"],
            "components": [
                "type": "array",
                "items": [
                    "type": "object",
                    "additionalProperties": false,
                    "required": ["name", "quantity", "unit", "grams", "usdaQuery", "fromLabel", "calories", "protein", "carbs", "fat"],
                    "properties": [
                        "name": ["type": "string"],
                        "quantity": ["type": "number"],
                        "unit": ["type": "string"],
                        "grams": ["type": "number"],
                        "usdaQuery": ["type": "string"],
                        "fromLabel": ["type": "boolean"],
                        "calories": ["type": "integer"],
                        "protein": ["type": "integer"],
                        "carbs": ["type": "integer"],
                        "fat": ["type": "integer"]
                    ]
                ]
            ]
        ]
    ]

    private static func error(_ code: Int, _ message: String) -> NSError {
        NSError(domain: "MealScan", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }

    /// First pass: identify the components and size them from the photo.
    func analyze(photo: UIImage, description: String) async throws -> MealScanResult {
        try await analyze(photo: photo, description: description, model: Self.scanModel).result
    }

    /// Same as `analyze(photo:description:)` on a chosen model, also returning token usage (used by the model comparison screen).
    func analyze(photo: UIImage, description: String, model: ScanModel) async throws -> (result: MealScanResult, usage: ScanUsage) {
        let note = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = note.isEmpty
            ? "Estimate this meal. Reason about scale first."
            : "The user describes this meal as: \"\(note)\"\n\nEstimate this meal. Reason about scale first."
        let (result, usage): (MealScanResult, ScanUsage) = try await sendWithUsage(system: Self.analyzePrompt, photo: photo, text: text, schema: Self.outputSchema, effort: "medium", model: model)
        guard result.isFood, !result.components.isEmpty else {
            throw Self.error(422, "We couldn't find any food in that photo.")
        }
        return (result, usage)
    }

    /// Re-estimates with the user's correction applied to the current components.
    func fix(photo: UIImage, name: String, components: [ScannedComponent], correction: String) async throws -> MealScanResult {
        let current = try JSONEncoder().encode(PreviousAnalysis(name: name, components: components))
        let text = """
        Your previous analysis:
        \(String(data: current, encoding: .utf8) ?? "")

        The user's correction: "\(correction)"

        Re-estimate the meal with this correction applied.
        """
        let result: MealScanResult = try await send(system: Self.fixPrompt, photo: photo, text: text, schema: Self.outputSchema, effort: "medium")
        guard !result.components.isEmpty else {
            throw Self.error(502, "Couldn't apply the fix. Please try again.")
        }
        return result
    }

    // MARK: - Text estimate

    static let describePrompt = """
    You estimate calories and macros from a text description of a meal or drink for the PumpCheck fitness app. There is no photo.

    Assume one typical serving unless the description says otherwise (e.g. a coffee is a regular ~350ml cup, "large" or "double" mean more). Break it into components the same way you would for a photo, including milk, sugar, oil, butter or sauces that are usually part of it.
    \(calibrationAnchors)

    Fields:
    - isFood: false only if the text clearly isn't food or drink.
    - reasoning: 1 sentence on the serving size you assumed.
    \(componentFields)
    """

    /// Estimates totals for a described meal (no photo), using USDA data where it matches.
    func estimate(description: String) async throws -> (calories: Int, protein: Int, carbs: Int, fat: Int) {
        let result: MealScanResult = try await send(system: Self.describePrompt, photo: nil, text: "Meal: \(description)", schema: Self.outputSchema, effort: "medium")
        guard result.isFood, !result.components.isEmpty else {
            throw Self.error(422, "That doesn't look like a food or drink.")
        }
        let usda = await matchUSDA(result.components)
        let components = zip(result.components, usda).map { EditableComponent($0, usda: $1) }
        return (
            components.reduce(0) { $0 + $1.calories },
            components.reduce(0) { $0 + $1.protein },
            components.reduce(0) { $0 + $1.carbs },
            components.reduce(0) { $0 + $1.fat }
        )
    }

    // MARK: - USDA lookup

    static let matchPrompt = """
    You match meal ingredients to entries in the USDA FoodData Central database. For each ingredient you get its description and a list of USDA candidates with their kcal per 100 g.

    Pick the candidate that is the same food in the same preparation: raw vs cooked, fried vs grilled or boiled, with or without skin. Use the kcal per 100 g to sanity-check. If no candidate is a reasonable match, return fdcId 0; a wrong match is worse than none.
    """

    private static let matchSchema: [String: Any] = [
        "type": "object",
        "additionalProperties": false,
        "required": ["matches"],
        "properties": [
            "matches": [
                "type": "array",
                "items": [
                    "type": "object",
                    "additionalProperties": false,
                    "required": ["index", "fdcId"],
                    "properties": [
                        "index": ["type": "integer"],
                        "fdcId": ["type": "integer"]
                    ]
                ]
            ]
        ]
    ]

    private struct MatchResult: Decodable {
        struct Match: Decodable { let index: Int; let fdcId: Int }
        let matches: [Match]
    }

    /// Finds a USDA entry for each component, or nil where there's no good match.
    /// Never throws: if the lookup fails, the AI's own estimates are used instead.
    func matchUSDA(_ components: [ScannedComponent]) async -> [USDAFood?] {
        var matches = [USDAFood?](repeating: nil, count: components.count)

        // Search USDA for every weighed, non-label component in parallel
        let candidates: [Int: [USDAFood]] = await withTaskGroup(of: (Int, [USDAFood]).self) { group in
            for (index, component) in components.enumerated()
            where !component.fromLabel && component.grams > 0 && !component.usdaQuery.isEmpty {
                group.addTask {
                    (index, (try? await USDAFoodService.shared.search(component.usdaQuery)) ?? [])
                }
            }
            var found: [Int: [USDAFood]] = [:]
            for await (index, foods) in group where !foods.isEmpty {
                found[index] = foods
            }
            return found
        }
        guard !candidates.isEmpty else { return matches }

        var text = ""
        for (index, foods) in candidates.sorted(by: { $0.key < $1.key }) {
            text += "Ingredient \(index): \(components[index].name)\n"
            for food in foods {
                text += "  - fdcId \(food.fdcId): \(food.description) (\(Int(food.calories)) kcal/100g)\n"
            }
            text += "\n"
        }

        guard let result: MatchResult = try? await send(system: Self.matchPrompt, photo: nil, text: text, schema: Self.matchSchema, effort: "low", model: Self.matchModel) else {
            return matches
        }
        for match in result.matches {
            guard let foods = candidates[match.index] else { continue }
            matches[match.index] = foods.first { $0.fdcId == match.fdcId }
        }
        return matches
    }

    /// Sends one request whose reply is constrained to `schema`; pass a photo to include it.
    private func send<T: Decodable>(system: String, photo: UIImage?, text: String, schema: [String: Any], effort: String, model: ScanModel = MealScanService.scanModel) async throws -> T {
        try await sendWithUsage(system: system, photo: photo, text: text, schema: schema, effort: effort, model: model).0
    }

    private func sendWithUsage<T: Decodable>(system: String, photo: UIImage?, text: String, schema: [String: Any], effort: String, model: ScanModel) async throws -> (T, ScanUsage) {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw URLError(.badURL)
        }
        var content: [[String: Any]] = []
        if let photo {
            guard let photoB64 = GuidedScanService.encode(photo) else {
                throw Self.error(400, "Could not process the photo.")
            }
            content.append(["type": "image", "source": ["type": "base64", "media_type": "image/jpeg", "data": photoB64]])
        }
        content.append(["type": "text", "text": text])

        var outputConfig: [String: Any] = ["format": ["type": "json_schema", "schema": schema]]
        var requestBody: [String: Any] = [
            "model": model.rawValue,
            "max_tokens": 16000,
            "system": system,
            "messages": [["role": "user", "content": content]]
        ]
        if model.supportsAdaptiveThinking {
            requestBody["thinking"] = ["type": "adaptive"]
            outputConfig["effort"] = effort
        }
        requestBody["output_config"] = outputConfig
        if model == .opus5 {
            // If the request is declined, the API retries it on a fallback model in the same call.
            requestBody["fallbacks"] = "default"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        if model == .opus5 {
            request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            #if DEBUG
            let detail = "API Error: " + (String(data: data, encoding: .utf8) ?? "Unknown Server Error")
            #else
            let detail = "We couldn't analyze your meal right now. Please try again in a moment."
            #endif
            throw Self.error((response as? HTTPURLResponse)?.statusCode ?? 500, detail)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Self.error(501, "Failed to read the analysis.")
        }

        switch json["stop_reason"] as? String {
        case "refusal":
            throw Self.error(422, "The AI couldn't analyze this photo. Try a different one.")
        case "max_tokens":
            throw Self.error(503, "The analysis was cut off. Please try again.")
        default:
            break
        }

        guard let content = json["content"] as? [[String: Any]],
              let textBlock = content.first(where: { $0["type"] as? String == "text" }),
              let resultText = textBlock["text"] as? String,
              let resultData = resultText.data(using: .utf8),
              let result = try? JSONDecoder().decode(T.self, from: resultData) else {
            throw Self.error(502, "Failed to read the analysis.")
        }
        let usageJSON = json["usage"] as? [String: Any]
        let usage = ScanUsage(
            inputTokens: usageJSON?["input_tokens"] as? Int ?? 0,
            outputTokens: usageJSON?["output_tokens"] as? Int ?? 0
        )
        return (result, usage)
    }
}

private struct PreviousAnalysis: Encodable {
    let name: String
    let components: [ScannedComponent]
}
