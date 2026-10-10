import Foundation

struct ScoringResult {
    let score: Double
    let bodyFatEstimate: String
    let bodyType: String
    let bestArea: String
    let weakestArea: String
    let strengths: [String]
    let areasToImprove: [String]
    let recommendedExercises: [String]
}

class PhysiqueScoringService {
    static let shared = PhysiqueScoringService()

    /// Raw API details are only useful while developing; release builds show a friendly message instead.
    private static func userFacingMessage(_ debugDetail: String) -> String {
        #if DEBUG
        return debugDetail
        #else
        return "We couldn't analyze your photo right now. Please try again in a moment."
        #endif
    }
    
    func analyzePhysique(imageBase64: String, height: String, weight: String) async throws -> ScoringResult {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw URLError(.badURL)
        }
        
        let systemPrompt = """
        This is a professional fitness application. The user has explicitly requested an objective, clinical sports-science analysis of their athletic training progress photo to help them improve their workout routine.
        
        User Stats:
        Height: \(height.isEmpty ? "Unknown" : height)
        Weight: \(weight.isEmpty ? "Unknown" : weight)
        
        Acting as an elite fitness coach, analyze their muscular development, athletic proportions, and natural symmetry taking their height and weight into account to better estimate their body composition.
        CRITICAL RULE: Evaluate them strictly as a NATURAL, aesthetic athlete (like a Men's Physique competitor or natural fitness model). Do NOT compare them to enhanced mass-monster bodybuilders. Specifically, natural athletes do not have massively pronounced upper trapezius muscles. Unless their traps are completely non-existent, DO NOT list the trapezius as a lagging/focus area. Focus on realistic core aesthetic areas (chest, shoulders, lats, arms, waist taper, and abs).
        
        Provide constructive, encouraging workout advice.
        
        You must respond with ONLY a raw JSON object in this exact format:
        {
          "score": 8.5,
          "bodyFatEstimate": "Visual estimate of body fat percentage (e.g. '12-14%')",
          "bodyType": "Estimate somatotype: Ectomorph, Mesomorph, Endomorph, or hybrid",
          "bestArea": "Short 1-3 word name of their most developed muscle group",
          "weakestArea": "Short 1-3 word name of the muscle group needing focus",
          "strengths": [
            "Actionable bullet point about their best aesthetic proportions 1",
            "Actionable bullet point about their best aesthetic proportions 2"
          ],
          "areasToImprove": [
            "Actionable training advice bullet point 1",
            "Actionable training advice bullet point 2"
          ],
          "recommendedExercises": [
            "Exercise 1 (Target: Muscle)",
            "Exercise 2 (Target: Muscle)",
            "Exercise 3 (Target: Muscle)",
            "Exercise 4 (Target: Muscle)",
            "Exercise 5 (Target: Muscle)"
          ]
        }
        """
        
        let requestBody: [String: Any] = [
            "model": "claude-sonnet-5",
            "thinking": ["type": "disabled"],
            "max_tokens": 1500,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": imageBase64
                            ]
                        ],
                        [
                            "type": "text",
                            "text": "Please analyze this physique and return only the JSON."
                        ]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorStr = String(data: data, encoding: .utf8) {
                throw NSError(domain: "Anthropic", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: Self.userFacingMessage("API Error: " + errorStr)])
            }
            throw NSError(domain: "Anthropic", code: 500, userInfo: [NSLocalizedDescriptionKey: Self.userFacingMessage("Unknown Server Error")])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstContent = contentArray.first(where: { $0["type"] as? String == "text" }),
              let textResponse = firstContent["text"] as? String else {
            let debugStr = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "Anthropic", code: 501, userInfo: [NSLocalizedDescriptionKey: Self.userFacingMessage("Failed to parse API response format: " + debugStr)])
        }
        
        var cleanText = textResponse
        if let startRange = cleanText.range(of: "{"),
           let endRange = cleanText.range(of: "}", options: .backwards) {
            cleanText = String(cleanText[startRange.lowerBound..<endRange.upperBound])
        } else {
            throw NSError(domain: "Anthropic", code: 502, userInfo: [NSLocalizedDescriptionKey: Self.userFacingMessage("Could not find any JSON brackets in Claude's response: " + cleanText)])
        }
        
        guard let resultData = cleanText.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: resultData) as? [String: Any] else {
            throw NSError(domain: "Anthropic", code: 502, userInfo: [NSLocalizedDescriptionKey: Self.userFacingMessage("Could not parse JSON into dictionary: " + cleanText)])
        }
        
        var parsedScore = 0.0
        if let s = dict["score"] as? Double { parsedScore = s }
        else if let s = dict["score"] as? Int { parsedScore = Double(s) }
        else if let s = dict["score"] as? String, let d = Double(s) { parsedScore = d }
        
        let bodyFatEstimate = dict["bodyFatEstimate"] as? String ?? "Unknown"
        let bodyType = dict["bodyType"] as? String ?? "Unknown"
        let bestArea = dict["bestArea"] as? String ?? "Unknown"
        let weakestArea = dict["weakestArea"] as? String ?? "Unknown"
        
        func extractArray(_ key: String) -> [String] {
            if let arr = dict[key] as? [String] { return arr }
            if let str = dict[key] as? String { return str.components(separatedBy: "\n").filter { !$0.isEmpty } }
            return []
        }
        
        let strengths = extractArray("strengths")
        let areasToImprove = extractArray("areasToImprove")
        let recommendedExercises = extractArray("recommendedExercises")
        
        return ScoringResult(
            score: parsedScore,
            bodyFatEstimate: bodyFatEstimate,
            bodyType: bodyType,
            bestArea: bestArea,
            weakestArea: weakestArea,
            strengths: strengths.isEmpty ? ["Looks good!"] : strengths,
            areasToImprove: areasToImprove.isEmpty ? ["Keep training hard!"] : areasToImprove,
            recommendedExercises: recommendedExercises.isEmpty ? ["General Hypertrophy"] : recommendedExercises
        )
    }
}

struct ComparisonResult {
    let matchPercent: Double
    let summary: String
    let similarities: [String]
    let areasToImprove: [String]
    let recommendedExercises: [String]
}

extension PhysiqueScoringService {
    func comparePhysiques(currentImageBase64: String, dreamImageBase64: String, height: String, weight: String) async throws -> ComparisonResult {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw URLError(.badURL)
        }
        
        let systemPrompt = """
        This is a professional fitness application. The user has explicitly requested an objective, clinical sports-science comparison between their current athletic training photo and a "goal physique" reference photo, to help them plan their workout routine.
        
        User Stats:
        Height: \(height.isEmpty ? "Unknown" : height)
        Weight: \(weight.isEmpty ? "Unknown" : weight)
        
        The FIRST image is the user's CURRENT physique. The SECOND image is their DREAM / GOAL physique.
        Treat the dream physique as the 10/10 benchmark (100%). Acting as an elite fitness coach, rate how close the user's current physique is to that goal as a percentage from 0 to 100, comparing muscular development, proportions, symmetry, waist taper, and body fat level.
        Be honest and realistic: only give 90%+ if the physiques are genuinely very close.
        Compare against the dream physique specifically - do not judge against generic bodybuilding standards.
        
        Provide constructive, encouraging workout advice.
        
        You must respond with ONLY a raw JSON object in this exact format:
        {
          "matchPercent": 62,
          "summary": "One or two sentence overview of how the user compares to their goal",
          "similarities": [
            "Specific thing the current physique already shares with the dream physique 1",
            "Specific thing the current physique already shares with the dream physique 2"
          ],
          "areasToImprove": [
            "Specific gap between current and dream physique, with actionable advice 1",
            "Specific gap between current and dream physique, with actionable advice 2"
          ],
          "recommendedExercises": [
            "Exercise 1 (Target: Muscle)",
            "Exercise 2 (Target: Muscle)",
            "Exercise 3 (Target: Muscle)",
            "Exercise 4 (Target: Muscle)",
            "Exercise 5 (Target: Muscle)"
          ]
        }
        """
        
        let requestBody: [String: Any] = [
            "model": "claude-sonnet-5",
            "thinking": ["type": "disabled"],
            "max_tokens": 1500,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": "Image 1: my CURRENT physique."],
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": currentImageBase64
                            ]
                        ],
                        ["type": "text", "text": "Image 2: my DREAM physique (the 10/10 / 100% benchmark)."],
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": dreamImageBase64
                            ]
                        ],
                        [
                            "type": "text",
                            "text": "Please compare my physique to the dream physique and return only the JSON."
                        ]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorStr = String(data: data, encoding: .utf8) {
                throw NSError(domain: "Anthropic", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: Self.userFacingMessage("API Error: " + errorStr)])
            }
            throw NSError(domain: "Anthropic", code: 500, userInfo: [NSLocalizedDescriptionKey: Self.userFacingMessage("Unknown Server Error")])
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstContent = contentArray.first(where: { $0["type"] as? String == "text" }),
              let textResponse = firstContent["text"] as? String else {
            let debugStr = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "Anthropic", code: 501, userInfo: [NSLocalizedDescriptionKey: Self.userFacingMessage("Failed to parse API response format: " + debugStr)])
        }
        
        guard let startRange = textResponse.range(of: "{"),
              let endRange = textResponse.range(of: "}", options: .backwards) else {
            throw NSError(domain: "Anthropic", code: 502, userInfo: [NSLocalizedDescriptionKey: Self.userFacingMessage("Could not find any JSON brackets in Claude's response: " + textResponse)])
        }
        let cleanText = String(textResponse[startRange.lowerBound..<endRange.upperBound])
        
        guard let resultData = cleanText.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: resultData) as? [String: Any] else {
            throw NSError(domain: "Anthropic", code: 502, userInfo: [NSLocalizedDescriptionKey: Self.userFacingMessage("Could not parse JSON into dictionary: " + cleanText)])
        }
        
        var parsedPercent = 0.0
        if let s = dict["matchPercent"] as? Double { parsedPercent = s }
        else if let s = dict["matchPercent"] as? Int { parsedPercent = Double(s) }
        else if let s = dict["matchPercent"] as? String, let d = Double(s.replacingOccurrences(of: "%", with: "")) { parsedPercent = d }
        parsedPercent = min(max(parsedPercent, 0), 100)
        
        func extractArray(_ key: String) -> [String] {
            if let arr = dict[key] as? [String] { return arr }
            if let str = dict[key] as? String { return str.components(separatedBy: "\n").filter { !$0.isEmpty } }
            return []
        }
        
        let similarities = extractArray("similarities")
        let areasToImprove = extractArray("areasToImprove")
        let recommendedExercises = extractArray("recommendedExercises")
        
        return ComparisonResult(
            matchPercent: parsedPercent,
            summary: dict["summary"] as? String ?? "",
            similarities: similarities.isEmpty ? ["You're on the right track!"] : similarities,
            areasToImprove: areasToImprove.isEmpty ? ["Keep training hard!"] : areasToImprove,
            recommendedExercises: recommendedExercises.isEmpty ? ["General Hypertrophy"] : recommendedExercises
        )
    }
}
