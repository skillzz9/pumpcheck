import sys

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

old_error_block = """        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorStr = String(data: data, encoding: .utf8) {
                print("Anthropic Error: \(errorStr)")
            }
            throw URLError(.badServerResponse)
        }
        
        // Claude returns {"content": [{"text": "{...}"}]}
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstContent = contentArray.first,
              let textResponse = firstContent["text"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        
        // Extract JSON string from potentially markdown-wrapped text
        var cleanText = textResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanText.hasPrefix("```json") {
            cleanText = cleanText.replacingOccurrences(of: "```json", with: "")
            if cleanText.hasSuffix("```") {
                cleanText = String(cleanText.dropLast(3))
            }
        }
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let decoder = JSONDecoder()
        guard let resultData = cleanText.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        
        return try decoder.decode(ScoringResult.self, from: resultData)"""

new_error_block = """        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorStr = String(data: data, encoding: .utf8) {
                throw NSError(domain: "Anthropic", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "API Error: " + errorStr])
            }
            throw NSError(domain: "Anthropic", code: 500, userInfo: [NSLocalizedDescriptionKey: "Unknown Server Error"])
        }
        
        // Claude returns {"content": [{"text": "{...}"}]}
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstContent = contentArray.first,
              let textResponse = firstContent["text"] as? String else {
            let debugStr = String(data: data, encoding: .utf8) ?? "unknown"
            throw NSError(domain: "Anthropic", code: 501, userInfo: [NSLocalizedDescriptionKey: "Failed to parse API response format: " + debugStr])
        }
        
        // Extract JSON string from potentially markdown-wrapped text
        var cleanText = textResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanText.hasPrefix("```json") {
            cleanText = cleanText.replacingOccurrences(of: "```json", with: "")
        }
        if cleanText.hasSuffix("```") {
            cleanText = String(cleanText.dropLast(3))
        }
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let decoder = JSONDecoder()
        guard let resultData = cleanText.data(using: .utf8) else {
            throw NSError(domain: "Anthropic", code: 502, userInfo: [NSLocalizedDescriptionKey: "Could not read JSON data from string: " + cleanText])
        }
        
        do {
            return try decoder.decode(ScoringResult.self, from: resultData)
        } catch {
            throw NSError(domain: "Anthropic", code: 503, userInfo: [NSLocalizedDescriptionKey: "Could not decode ScoringResult. Model returned: " + cleanText])
        }"""

# A somewhat safer replace string just in case
start_marker = "        guard let httpResponse = response as? HTTPURLResponse"
end_marker = "        return try decoder.decode(ScoringResult.self, from: resultData)"
idx1 = content.find(start_marker)
idx2 = content.find(end_marker)

if idx1 != -1 and idx2 != -1:
    content = content[:idx1] + new_error_block + content[idx2 + len(end_marker):]

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

