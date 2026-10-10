import sys

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "r") as f:
    content = f.read()

old_model = '"model": "claude-3-5-sonnet-20241022"'
new_model = '"model": "claude-opus-4-5-20251101"'

if old_model not in content:
    # Just in case it was left as claude-sonnet-5-5 or something else in the revert
    import re
    content = re.sub(r'"model":\s*"[^"]+"', new_model, content)
else:
    content = content.replace(old_model, new_model)

with open("PumpCheck.swiftpm/Onboarding/PhysiqueScoringService.swift", "w") as f:
    f.write(content)

