import sys

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

old_prompt = """        let systemPrompt = \"\"\"
        This is a professional fitness application. The user has explicitly requested an objective, clinical sports-science analysis of their athletic training progress photo to help them improve their workout routine.
        
        Acting as an elite fitness coach, analyze their muscular development, athletic proportions, and natural symmetry. Provide constructive, encouraging workout advice.
        
        You must respond with ONLY a raw JSON object in this exact format:"""

new_prompt = """        let systemPrompt = \"\"\"
        This is a professional fitness application. The user has explicitly requested an objective, clinical sports-science analysis of their athletic training progress photo to help them improve their workout routine.
        
        Acting as an elite fitness coach, analyze their muscular development, athletic proportions, and natural symmetry. 
        CRITICAL RULE: Evaluate them strictly as a NATURAL, aesthetic athlete (like a Men's Physique competitor or natural fitness model). Do NOT compare them to enhanced mass-monster bodybuilders. Specifically, natural athletes do not have massively pronounced upper trapezius muscles. Unless their traps are completely non-existent, DO NOT list the trapezius as a lagging/focus area. Focus on realistic core aesthetic areas (chest, shoulders, lats, arms, waist taper, and abs).
        
        Provide constructive, encouraging workout advice.
        
        You must respond with ONLY a raw JSON object in this exact format:"""

content = content.replace(old_prompt, new_prompt)

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

