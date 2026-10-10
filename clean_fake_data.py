import sys

with open("PumpCheck.swiftpm/Onboarding/StatsView.swift", "r") as f:
    content = f.read()

import re
content = re.sub(r'    private func generateFakeData\(.*?\)\s*->\s*\[ChartDataPoint\]\s*\{.*?\n    \}\n', '', content, flags=re.DOTALL)

with open("PumpCheck.swiftpm/Onboarding/StatsView.swift", "w") as f:
    f.write(content)

