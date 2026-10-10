import sys

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

old_model = '"model": "claude-3-haiku-20240307"'
new_model = '"model": "claude-3-5-sonnet-20240620"'

content = content.replace(old_model, new_model)

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

