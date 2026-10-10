import sys

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

old_parse = """        let decoder = JSONDecoder()
        guard let resultData = cleanText.data(using: .utf8) else {
            throw NSError(domain: "Anthropic", code: 502, userInfo: [NSLocalizedDescriptionKey: "Could not read JSON data from string: " + cleanText])
        }
        
        do {
            return try decoder.decode(ScoringResult.self, from: resultData)
        } catch {
            throw NSError(domain: "Anthropic", code: 503, userInfo: [NSLocalizedDescriptionKey: "Could not decode ScoringResult. Model returned: " + cleanText])
        }"""

new_parse = """        guard let resultData = cleanText.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: resultData) as? [String: Any] else {
            throw NSError(domain: "Anthropic", code: 502, userInfo: [NSLocalizedDescriptionKey: "Could not parse Claude's response into a dictionary: " + cleanText])
        }
        
        // Safely extract score (could be Double, Int, or String)
        var parsedScore: Double = 0.0
        if let s = dict["score"] as? Double { parsedScore = s }
        else if let s = dict["score"] as? Int { parsedScore = Double(s) }
        else if let s = dict["score"] as? String, let d = Double(s) { parsedScore = d }
        
        let bodyType = dict["bodyType"] as? String ?? "Unknown"
        let bestArea = dict["bestArea"] as? String ?? "Unknown"
        let weakestArea = dict["weakestArea"] as? String ?? "Unknown"
        
        // Safely extract strengths (could be String or Array)
        var parsedStrengths = ""
        if let st = dict["strengths"] as? String {
            parsedStrengths = st
        } else if let stArr = dict["strengths"] as? [String] {
            parsedStrengths = stArr.joined(separator: "\\n")
        }
        
        // Safely extract areasToImprove (could be String or Array)
        var parsedAreas: [String] = []
        if let ar = dict["areasToImprove"] as? [String] {
            parsedAreas = ar
        } else if let arStr = dict["areasToImprove"] as? String {
            parsedAreas = [arStr]
        }
        
        // Safely extract recommendedExercises
        let parsedExercises = dict["recommendedExercises"] as? [String] ?? []
        
        return ScoringResult(
            score: parsedScore,
            bodyType: bodyType,
            bestArea: bestArea,
            weakestArea: weakestArea,
            strengths: parsedStrengths,
            areasToImprove: parsedAreas.isEmpty ? ["Keep training hard!"] : parsedAreas,
            recommendedExercises: parsedExercises.isEmpty ? ["General Hypertrophy Training"] : parsedExercises
        )"""

start_marker = "        let decoder = JSONDecoder()"
end_marker = "        } catch {\n            throw NSError(domain: \"Anthropic\", code: 503, userInfo: [NSLocalizedDescriptionKey: \"Could not decode ScoringResult. Model returned: \" + cleanText])\n        }"

idx1 = content.find(start_marker)
idx2 = content.find(end_marker)

if idx1 != -1 and idx2 != -1:
    content = content[:idx1] + new_parse + content[idx2 + len(end_marker):]
else:
    print("Could not find markers!")

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

