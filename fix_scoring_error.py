import sys

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

old_err = """        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorStr = String(data: data, encoding: .utf8) {
                print("Anthropic Error: \\(errorStr)")
            }
            throw URLError(.badServerResponse)
        }"""

new_err = """        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorStr = String(data: data, encoding: .utf8) {
                throw NSError(domain: "Anthropic", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorStr])
            }
            throw URLError(.badServerResponse)
        }"""

content = content.replace(old_err, new_err)

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

