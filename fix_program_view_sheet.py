import sys

with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "r") as f:
    content = f.read()

old_sheet = """        .sheet(isPresented: $showScoringTest) {
            TestScoringView()
        }"""

new_sheet = """        .sheet(isPresented: $showScoringTest) {
            TestScoringView(viewModel: viewModel)
        }"""
content = content.replace(old_sheet, new_sheet)

with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "w") as f:
    f.write(content)

