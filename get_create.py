with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "r") as f:
    content = f.read()

import re
match = re.search(r'func createAccount\(\) async throws \{(.*?)\} \w+ func', content, re.DOTALL)
if match:
    print(match.group(1))
