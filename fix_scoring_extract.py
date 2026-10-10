import sys

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

old_extract = """        // Extract JSON string from potentially markdown-wrapped text
        var cleanText = textResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanText.hasPrefix("```json") {
            cleanText = cleanText.replacingOccurrences(of: "```json", with: "")
        }
        if cleanText.hasSuffix("```") {
            cleanText = String(cleanText.dropLast(3))
        }
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)"""

new_extract = """        // Extract JSON string from potentially markdown-wrapped text
        var cleanText = textResponse
        if let startRange = cleanText.range(of: "{"),
           let endRange = cleanText.range(of: "}", options: .backwards) {
            cleanText = String(cleanText[startRange.lowerBound...endRange.upperBound])
        } else {
            throw NSError(domain: "Anthropic", code: 502, userInfo: [NSLocalizedDescriptionKey: "Could not find any JSON brackets in Claude's response: " + cleanText])
        }"""

content = content.replace(old_extract, new_extract)

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

