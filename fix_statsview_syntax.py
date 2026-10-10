import sys

with open("PumpCheck.swiftpm/Onboarding/StatsView.swift", "r") as f:
    content = f.read()

old_bad = """        .navigationTitle("\(username)'s Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
    
        .task {
            await fetchProgress()
        }
    }"""

new_good = """        .navigationTitle("\(username)'s Stats")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await fetchProgress()
        }
    }"""

content = content.replace(old_bad, new_good)

with open("PumpCheck.swiftpm/Onboarding/StatsView.swift", "w") as f:
    f.write(content)

