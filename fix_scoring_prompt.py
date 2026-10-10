import sys

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

# 1. Update ScoringResult struct
old_struct = """struct ScoringResult: Codable {
    let score: Double
    let strengths: String
    let areasToImprove: String
}"""

new_struct = """struct ScoringResult: Codable {
    let score: Double
    let strengths: String
    let areasToImprove: String
    let recommendedExercises: [String]
}"""

content = content.replace(old_struct, new_struct)

# 2. Update System Prompt
old_prompt = """        let systemPrompt = \"\"\"
        You are an objective, professional bodybuilding and fitness coach. Your task is to perform a sports-science assessment of the provided physique based on standard bodybuilding criteria: muscle hypertrophy, leanness, and anatomical symmetry.
        
        Do not use subjective or insulting language. Provide a clinical, constructive athletic assessment.
        
        You must respond with ONLY a raw JSON object in this exact format:
        {
          "score": 8.5,
          "strengths": "1-2 sentences highlighting the most developed muscle groups or best proportions",
          "areasToImprove": "1-2 sentences offering constructive, athletic advice on which muscle groups to focus on for better symmetry"
        }
        \"\"\""""

new_prompt = """        let systemPrompt = \"\"\"
        You are an elite, objective fitness and aesthetics coach. Your task is to perform an assessment of the provided physique based on natural aesthetics, athletic proportions, v-taper, and healthy leanness—NOT mass-monster bodybuilding standards. Evaluate their natural muscular development, shoulder-to-waist ratio, and overall aesthetic harmony.
        
        Do not use subjective or insulting language. Provide a clinical, constructive, and highly detailed athletic assessment.
        
        You must respond with ONLY a raw JSON object in this exact format:
        {
          "score": 8.5,
          "strengths": "2-3 sentences highlighting their best aesthetic proportions, most developed muscle groups, and leanness.",
          "areasToImprove": "2-3 sentences offering constructive advice on which muscle groups to focus on for better natural aesthetic harmony.",
          "recommendedExercises": [
             "Name of Exercise 1 (Target: Muscle)",
             "Name of Exercise 2 (Target: Muscle)",
             "Name of Exercise 3 (Target: Muscle)",
             "Name of Exercise 4 (Target: Muscle)",
             "Name of Exercise 5 (Target: Muscle)"
          ]
        }
        \"\"\""""

content = content.replace(old_prompt, new_prompt)

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

