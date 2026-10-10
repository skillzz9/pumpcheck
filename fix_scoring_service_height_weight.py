import sys

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

# Modify function signature
old_func = "func analyzePhysique(imageBase64: String) async throws -> ScoringResult {"
new_func = "func analyzePhysique(imageBase64: String, height: String, weight: String) async throws -> ScoringResult {"
content = content.replace(old_func, new_func)

# Modify system prompt to inject height and weight
old_prompt = """        let systemPrompt = \"\"\"
        This is a professional fitness application. The user has explicitly requested an objective, clinical sports-science analysis of their athletic training progress photo to help them improve their workout routine.
        
        Acting as an elite fitness coach, analyze their muscular development, athletic proportions, and natural symmetry."""

new_prompt = """        let systemPrompt = \"\"\"
        This is a professional fitness application. The user has explicitly requested an objective, clinical sports-science analysis of their athletic training progress photo to help them improve their workout routine.
        
        User Stats:
        Height: \\(height.isEmpty ? "Unknown" : height)
        Weight: \\(weight.isEmpty ? "Unknown" : weight)
        
        Acting as an elite fitness coach, analyze their muscular development, athletic proportions, and natural symmetry taking their height and weight into account to better estimate their body composition."""

content = content.replace(old_prompt, new_prompt)

# Add bodyFatEstimate to ScoringResult
old_struct = """struct ScoringResult {
    let score: Double
    let bodyType: String
    let bestArea: String
    let weakestArea: String"""

new_struct = """struct ScoringResult {
    let score: Double
    let bodyFatEstimate: String
    let bodyType: String
    let bestArea: String
    let weakestArea: String"""
content = content.replace(old_struct, new_struct)

# Add bodyFatEstimate to JSON prompt instructions
old_json_req = """        {
          "score": 8.5,
          "bodyType": "Estimate somatotype: Ectomorph, Mesomorph, Endomorph, or hybrid",
          "bestArea": "Short 1-3 word name of their most developed muscle group","""

new_json_req = """        {
          "score": 8.5,
          "bodyFatEstimate": "Visual estimate of body fat percentage (e.g. '12-14%')",
          "bodyType": "Estimate somatotype: Ectomorph, Mesomorph, Endomorph, or hybrid",
          "bestArea": "Short 1-3 word name of their most developed muscle group","""
content = content.replace(old_json_req, new_json_req)

# Add bodyFatEstimate extraction
old_extract = """        let bodyType = dict["bodyType"] as? String ?? "Unknown"
        let bestArea = dict["bestArea"] as? String ?? "Unknown"
        let weakestArea = dict["weakestArea"] as? String ?? "Unknown\"\"\""""

new_extract = """        let bodyFatEstimate = dict["bodyFatEstimate"] as? String ?? "Unknown"
        let bodyType = dict["bodyType"] as? String ?? "Unknown"
        let bestArea = dict["bestArea"] as? String ?? "Unknown"
        let weakestArea = dict["weakestArea"] as? String ?? "Unknown\"\"\""""
        
# Just in case string matching gets weird, doing it via lines
lines = content.split('\\n')
for i, line in enumerate(lines):
    if 'let bodyType = dict["bodyType"]' in line:
        lines.insert(i, '        let bodyFatEstimate = dict["bodyFatEstimate"] as? String ?? "Unknown"')
        break
content = '\\n'.join(lines)

# Return ScoringResult modification
old_ret = """        return ScoringResult(
            score: parsedScore,
            bodyType: bodyType,
            bestArea: bestArea,"""

new_ret = """        return ScoringResult(
            score: parsedScore,
            bodyFatEstimate: bodyFatEstimate,
            bodyType: bodyType,
            bestArea: bestArea,"""
content = content.replace(old_ret, new_ret)

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

