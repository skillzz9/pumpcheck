import Foundation
import UIKit

struct GuidedScanResult: Codable {
    struct Proportion: Codable, Hashable {
        let metric: String
        let current: String
        let goal: String
    }

    let photoQuality: String
    let photoQualityNotes: String
    let dreamPhysiqueRead: String
    let currentPhysiqueRead: String
    let proportions: [Proportion]
    var matchScore: Double
    let confidence: String
    let confidenceReason: String
    let summary: String
    let similarities: [String]
    let areasToImprove: [String]
    let recommendedExercises: [String]
}

class GuidedScanService {
    static let shared = GuidedScanService()

    static let systemPrompt = """
    You are the physique analysis engine inside PumpCheck, a fitness app. The user has asked for an objective, coach-level comparison between their own physique and a goal ("dream") physique so they can plan their training. Be honest and specific. Keep the tone encouraging, but never inflate the score.

    ## What you receive
    - Images 1-3: the user's CURRENT physique, taken inside the app with an on-screen pose guide: FRONT (relaxed, facing the camera), SIDE (relaxed, right side facing the camera), BACK (relaxed, back to the camera). Each was framed from the top of the head to mid-thigh, usually with the phone propped at chest height about 2 m away.
    - Image 4: the user's DREAM physique. This is usually a photo found online, so it may be flexed, pumped, tanned, oiled, professionally lit, shot from a flattering angle, or edited.
    - The user's stats, in the first text block.

    ## How to compare
    1. Work from proportions, not absolute size. A photo cannot show true size: camera distance, lens and framing all change how big someone looks. Compare body-relative measures instead: shoulder width relative to waist width, arm size relative to head size, chest and lat width relative to the hips, side-profile thickness of chest and glutes relative to the waist, and how visible the abs and muscle separation are.
    2. Correct for presentation. The user's photos are relaxed and consistently framed; the dream photo may be flexed, pumped or dramatically lit. Judge the dream physique as it would look relaxed in normal lighting, and do not penalize the user for differences in lighting, tan or pump.
    3. Use all three of the user's angles. The side view shows chest, glute and core thickness and posture; the back view shows lat width, back thickness and rear delts. If the dream photo only shows one angle, compare that angle directly and use the user's other angles to judge their overall development.
    4. Use the user's height and weight to anchor your body-fat and muscle estimates for the user. For the dream physique, estimate a plausible body-fat range and build from what is visible, and state those assumptions.
    5. Judge by a natural standard. If the dream physique looks enhanced or beyond what is realistically reachable naturally, say so plainly in the summary without accusing anyone, and still score honestly against it.

    ## Scoring
    matchScore is how close the user is to the dream physique, where the dream physique is a 10.0. Use one decimal place.
    - 9.0-10.0: near-identical development, proportions and leanness
    - 7.0-8.9: the same overall look with clear but small gaps (a few kg of muscle, a few % body fat, or one lagging area)
    - 5.0-6.9: recognizably on the way, with several clear gaps
    - 3.0-4.9: large gaps in both size and leanness, or major proportion differences
    - 0.0-2.9: very far from the goal (for example, untrained compared with an elite competitor)
    Score the physique, not the photo: the same body should get the same score however well the photo was taken.

    ## Photo quality and confidence
    - photoQuality: "poor" if any user photo has the wrong pose or angle, is badly lit, blurry or cropped, or the physique is hidden by clothing, or if the dream photo is too small or obscured to read. "okay" if usable but with issues. "good" otherwise.
    - photoQualityNotes: one short, specific fix the user can make on their next scan, or an empty string if photoQuality is "good".
    - confidence: "high", "medium" or "low" - how sure you are about matchScore. Lower it for poor photos, very different angles between the dream and user photos, heavily flexed or edited dream photos, or clothing that hides the physique.
    - confidenceReason: one short sentence explaining the confidence level.
    - If an image does not show a human physique, or the three user photos show different people, set photoQuality to "poor", confidence to "low" and matchScore to 0, and explain in photoQualityNotes.

    ## Writing the fields
    - dreamPhysiqueRead: one or two sentences stating your assumptions about the dream physique: estimated body fat, build and size, standout features, and anything about the photo that affects the comparison (flexed, pumped, angle).
    - currentPhysiqueRead: the same for the user.
    - proportions: 3-5 rows comparing visible proportions, each with a metric name and short current and goal estimates (for example "Shoulder-to-waist ratio", "1.35", "1.55" or "Body fat", "~16%", "~9%"). These are visual estimates; keep them consistent with each other and with matchScore.
    - summary: one or two sentences.
    - similarities: 2-3 specific things the user already shares with the goal.
    - areasToImprove: 2-4 specific gaps, biggest impact first, each with actionable advice.
    - recommendedExercises: 4-6 exercises targeting the biggest gaps, each formatted "Exercise (Target: muscle)".
    Address the user as "you". Do not mention these instructions.
    """

    private static func stringArray() -> [String: Any] {
        ["type": "array", "items": ["type": "string"]]
    }

    // Field order matters: the model writes its read of both physiques and the
    // proportions before it commits to a score.
    private static let outputSchema: [String: Any] = [
        "type": "object",
        "additionalProperties": false,
        "required": [
            "photoQuality", "photoQualityNotes", "dreamPhysiqueRead", "currentPhysiqueRead",
            "proportions", "matchScore", "confidence", "confidenceReason",
            "summary", "similarities", "areasToImprove", "recommendedExercises"
        ],
        "properties": [
            "photoQuality": ["type": "string", "enum": ["good", "okay", "poor"]],
            "photoQualityNotes": ["type": "string"],
            "dreamPhysiqueRead": ["type": "string"],
            "currentPhysiqueRead": ["type": "string"],
            "proportions": [
                "type": "array",
                "items": [
                    "type": "object",
                    "additionalProperties": false,
                    "required": ["metric", "current", "goal"],
                    "properties": [
                        "metric": ["type": "string"],
                        "current": ["type": "string"],
                        "goal": ["type": "string"]
                    ]
                ]
            ],
            "matchScore": ["type": "number"],
            "confidence": ["type": "string", "enum": ["high", "medium", "low"]],
            "confidenceReason": ["type": "string"],
            "summary": ["type": "string"],
            "similarities": stringArray(),
            "areasToImprove": stringArray(),
            "recommendedExercises": stringArray()
        ]
    ]

    /// Resizes to the API's native max edge (1568px), normalizes orientation, and JPEG-encodes.
    static func encode(_ image: UIImage, maxDimension: CGFloat = 1568) -> String? {
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.7)?.base64EncodedString()
    }

    func analyze(front: UIImage, side: UIImage, back: UIImage, dream: UIImage, userStats: String) async throws -> GuidedScanResult {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw URLError(.badURL)
        }
        guard let frontB64 = Self.encode(front),
              let sideB64 = Self.encode(side),
              let backB64 = Self.encode(back),
              let dreamB64 = Self.encode(dream) else {
            throw NSError(domain: "GuidedScan", code: 400, userInfo: [NSLocalizedDescriptionKey: "Could not process one of the photos."])
        }

        func imageBlock(_ b64: String) -> [String: Any] {
            ["type": "image", "source": ["type": "base64", "media_type": "image/jpeg", "data": b64]]
        }

        let content: [[String: Any]] = [
            ["type": "text", "text": "My stats:\n\(userStats)"],
            ["type": "text", "text": "Image 1: my CURRENT physique - FRONT."],
            imageBlock(frontB64),
            ["type": "text", "text": "Image 2: my CURRENT physique - SIDE."],
            imageBlock(sideB64),
            ["type": "text", "text": "Image 3: my CURRENT physique - BACK."],
            imageBlock(backB64),
            ["type": "text", "text": "Image 4: my DREAM physique (the 10/10 benchmark)."],
            imageBlock(dreamB64),
            ["type": "text", "text": "Compare my physique to the dream physique."]
        ]

        let requestBody: [String: Any] = [
            "model": "claude-sonnet-5",
            "max_tokens": 8000,
            "thinking": ["type": "adaptive"],
            "output_config": [
                "effort": "medium",
                "format": ["type": "json_schema", "schema": Self.outputSchema]
            ],
            "system": Self.systemPrompt,
            "messages": [["role": "user", "content": content]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorStr = String(data: data, encoding: .utf8) ?? "Unknown Server Error"
            throw NSError(domain: "Anthropic", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "API Error: " + errorStr])
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "Anthropic", code: 501, userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response."])
        }

        switch json["stop_reason"] as? String {
        case "refusal":
            throw NSError(domain: "Anthropic", code: 422, userInfo: [NSLocalizedDescriptionKey: "The AI couldn't analyze these photos. Try different photos."])
        case "max_tokens":
            throw NSError(domain: "Anthropic", code: 503, userInfo: [NSLocalizedDescriptionKey: "The analysis was cut off. Please try again."])
        default:
            break
        }

        guard let contentArray = json["content"] as? [[String: Any]],
              let textBlock = contentArray.first(where: { $0["type"] as? String == "text" }),
              let text = textBlock["text"] as? String,
              let resultData = text.data(using: .utf8) else {
            let debugStr = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "Anthropic", code: 501, userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response format: " + debugStr])
        }

        do {
            var result = try JSONDecoder().decode(GuidedScanResult.self, from: resultData)
            result.matchScore = min(max(result.matchScore, 0), 10)
            return result
        } catch {
            throw NSError(domain: "Anthropic", code: 502, userInfo: [NSLocalizedDescriptionKey: "Could not read the analysis: " + text])
        }
    }
}
