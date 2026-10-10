import sys

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

# 1. Update ScoringResult struct
old_struct = """struct ScoringResult: Codable {
    let score: Double
    let bodyType: String
    let bestArea: String
    let weakestArea: String
    let strengths: String
    let areasToImprove: String
    let recommendedExercises: [String]
}"""

new_struct = """struct ScoringResult: Codable {
    let score: Double
    let bodyType: String
    let bestArea: String
    let weakestArea: String
    let strengths: String
    let areasToImprove: [String]
    let recommendedExercises: [String]
}"""
content = content.replace(old_struct, new_struct)

# 2. Update System Prompt
old_prompt_json = """          "weakestArea": "Short 1-3 word name of their most lagging muscle group.",
          "strengths": "2-3 sentences highlighting their best aesthetic proportions, most developed muscle groups, and leanness.",
          "areasToImprove": "2-3 sentences offering constructive advice on which muscle groups to focus on for better natural aesthetic harmony.",
          "recommendedExercises": ["""

new_prompt_json = """          "weakestArea": "Short 1-3 word name of their most lagging muscle group.",
          "strengths": "2-3 sentences highlighting their best aesthetic proportions, most developed muscle groups, and leanness.",
          "areasToImprove": [
             "Specific, actionable bullet point of advice 1",
             "Specific, actionable bullet point of advice 2",
             "Specific, actionable bullet point of advice 3"
          ],
          "recommendedExercises": ["""
content = content.replace(old_prompt_json, new_prompt_json)

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

