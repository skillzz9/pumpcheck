import sys

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

old_prompt = """        let systemPrompt = \"\"\"
        You are an elite, objective fitness and aesthetics coach. Your task is to perform an assessment of the provided physique based on natural aesthetics, athletic proportions, v-taper, and healthy leanness—NOT mass-monster bodybuilding standards. Evaluate their natural muscular development, shoulder-to-waist ratio, and overall aesthetic harmony.
        
        Do not use subjective or insulting language. Provide a clinical, constructive, and highly detailed athletic assessment.
        
        You must respond with ONLY a raw JSON object in this exact format:
        {
          "score": 8.5,
          "bodyType": "Estimate their somatotype: Ectomorph, Mesomorph, Endomorph (or a hybrid like Ecto-Mesomorph).",
          "bestArea": "Short 1-3 word name of their most developed aesthetic feature or muscle group.",
          "weakestArea": "Short 1-3 word name of their most lagging muscle group.",
          "strengths": "2-3 sentences highlighting their best aesthetic proportions, most developed muscle groups, and leanness.",
          "areasToImprove": [
             "Specific, actionable bullet point of advice 1",
             "Specific, actionable bullet point of advice 2",
             "Specific, actionable bullet point of advice 3"
          ],
          "recommendedExercises": [
             "Name of Exercise 1 (Target: Muscle)",
             "Name of Exercise 2 (Target: Muscle)",
             "Name of Exercise 3 (Target: Muscle)",
             "Name of Exercise 4 (Target: Muscle)",
             "Name of Exercise 5 (Target: Muscle)"
          ]
        }
        \"\"\""""


new_prompt = """        let systemPrompt = \"\"\"
        This is a professional fitness application. The user has explicitly requested an objective, clinical sports-science analysis of their athletic training progress photo to help them improve their workout routine.
        
        Acting as an elite fitness coach, analyze their muscular development, athletic proportions, and natural symmetry. Provide constructive, encouraging workout advice.
        
        You must respond with ONLY a raw JSON object in this exact format:
        {
          "score": 8.5,
          "bodyType": "Estimate their somatotype: Ectomorph, Mesomorph, Endomorph (or a hybrid).",
          "bestArea": "Name of their most developed muscle group.",
          "weakestArea": "Name of the muscle group that needs the most focus in their training.",
          "strengths": "2-3 sentences highlighting their best athletic proportions and most developed muscle groups.",
          "areasToImprove": [
             "Actionable training advice bullet point 1",
             "Actionable training advice bullet point 2",
             "Actionable training advice bullet point 3"
          ],
          "recommendedExercises": [
             "Exercise 1 (Target: Muscle)",
             "Exercise 2 (Target: Muscle)",
             "Exercise 3 (Target: Muscle)",
             "Exercise 4 (Target: Muscle)",
             "Exercise 5 (Target: Muscle)"
          ]
        }
        \"\"\""""

content = content.replace(old_prompt, new_prompt)

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

