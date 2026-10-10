import sys

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

# 1. Update ScoringResult struct
old_struct = """struct ScoringResult: Codable {
    let score: Double
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
    let areasToImprove: String
    let recommendedExercises: [String]
}"""
content = content.replace(old_struct, new_struct)

# 2. Update System Prompt
old_prompt_json = """        You must respond with ONLY a raw JSON object in this exact format:
        {
          "score": 8.5,
          "strengths": "2-3 sentences highlighting their best aesthetic proportions, most developed muscle groups, and leanness.",
          "areasToImprove": "2-3 sentences offering constructive advice on which muscle groups to focus on for better natural aesthetic harmony.",
          "recommendedExercises": ["""

new_prompt_json = """        You must respond with ONLY a raw JSON object in this exact format:
        {
          "score": 8.5,
          "bodyType": "Estimate their somatotype: Ectomorph, Mesomorph, Endomorph (or a hybrid like Ecto-Mesomorph).",
          "bestArea": "Short 1-3 word name of their most developed aesthetic feature or muscle group.",
          "weakestArea": "Short 1-3 word name of their most lagging muscle group.",
          "strengths": "2-3 sentences highlighting their best aesthetic proportions, most developed muscle groups, and leanness.",
          "areasToImprove": "2-3 sentences offering constructive advice on which muscle groups to focus on for better natural aesthetic harmony.",
          "recommendedExercises": ["""
content = content.replace(old_prompt_json, new_prompt_json)

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

