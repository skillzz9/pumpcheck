import sys

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

old_tokens = '"max_tokens": 500'
new_tokens = '"max_tokens": 1500'

content = content.replace(old_tokens, new_tokens)

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

