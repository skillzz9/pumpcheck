import sys

with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "r") as f:
    content = f.read()

# Try to find where selectedDate is defined and add our new states right after it
import re
pattern = r'(@State private var selectedDate[^\\n]*\\n)'
replacement = r'\\1\n    @State private var scale: CGFloat = 1.0\n    @State private var offset: CGSize = .zero\n    @State private var lastScale: CGFloat = 1.0\n    @State private var lastOffset: CGSize = .zero\n    @State private var cropSize: CGSize = .zero\n'

content = re.sub(pattern, replacement, content)

with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "w") as f:
    f.write(content)

