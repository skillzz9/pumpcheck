import sys
import re

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

# Fix the broken import line
content = content.replace('        let bodyFatEstimate = dict["bodyFatEstimate"] as? String ?? "Unknown"\\nimport Foundation', 'import Foundation')

# Now insert the bodyFatEstimate safely
old_block = """        var parsedScore = 0.0
        if let s = dict["score"] as? Double { parsedScore = s }
        else if let s = dict["score"] as? Int { parsedScore = Double(s) }
        else if let s = dict["score"] as? String, let d = Double(s) { parsedScore = d }
        
        let bodyType = dict["bodyType"] as? String ?? "Unknown"
        let bestArea = dict["bestArea"] as? String ?? "Unknown"
        let weakestArea = dict["weakestArea"] as? String ?? "Unknown\"\"\""""

new_block = """        var parsedScore = 0.0
        if let s = dict["score"] as? Double { parsedScore = s }
        else if let s = dict["score"] as? Int { parsedScore = Double(s) }
        else if let s = dict["score"] as? String, let d = Double(s) { parsedScore = d }
        
        let bodyFatEstimate = dict["bodyFatEstimate"] as? String ?? "Unknown"
        let bodyType = dict["bodyType"] as? String ?? "Unknown"
        let bestArea = dict["bestArea"] as? String ?? "Unknown"
        let weakestArea = dict["weakestArea"] as? String ?? "Unknown\"\"\""""

content = content.replace(old_block, new_block)

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

