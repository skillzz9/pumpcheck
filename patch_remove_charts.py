import re

# Patch PublicProfileView.swift
with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "r") as f:
    content = f.read()

# Remove StatChartView struct and ChartDataPoint
content = re.sub(r"struct ChartDataPoint: Identifiable \{.*?\}\n*", "", content, flags=re.DOTALL)
content = re.sub(r"struct StatChartView: View \{.*?\.presentationDetents\(\[\.fraction\(0\.6\)\]\)\n    \}\n\}\n", "", content, flags=re.DOTALL)

# Remove the .sheet modifiers
content = re.sub(r"\.sheet\(isPresented: \$showHeightChart\) \{.*?\n        \}", "", content, flags=re.DOTALL)
content = re.sub(r"\.sheet\(isPresented: \$showWeightChart\) \{.*?\n        \}", "", content, flags=re.DOTALL)
content = re.sub(r"\.sheet\(isPresented: Binding\(get: \{ selectedLiftChartName != nil \}.*?\n        \}", "", content, flags=re.DOTALL)
content = re.sub(r"private func generateFakeData\(.*?return data\n    \}", "", content, flags=re.DOTALL)

# Replace the @State variables with navigation destination variables
content = re.sub(r"@State private var showHeightChart = false\n    @State private var showWeightChart = false\n    @State private var selectedLiftChartName: String\? = nil", 
"""@State private var navToStats: Bool = false
    @State private var initialStatSelection: StatSelection = .height""", content)

# Change the Pill Buttons to set the navigation states
content = re.sub(r"Button \{ showHeightChart = true \} label:", "Button { initialStatSelection = .height; navToStats = true } label:", content)
content = re.sub(r"Button \{ showWeightChart = true \} label:", "Button { initialStatSelection = .weight; navToStats = true } label:", content)
content = re.sub(r"Button \{ selectedLiftChartName = lift.name \} label:", "Button { initialStatSelection = .lift(lift.name); navToStats = true } label:", content)

# Add NavigationDestination at the end of the body
content = content.replace(".task {\n            await fetchPublicProfile()\n        }", 
""".task {\n            await fetchPublicProfile()\n        }
        .navigationDestination(isPresented: $navToStats) {
            StatsView(username: username, heightStr: height, weightStr: weight, lifts: proudestLifts, selection: initialStatSelection)
        }""")

with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "w") as f:
    f.write(content)


# Patch ProfileView.swift
with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content2 = f.read()

content2 = re.sub(r"\.sheet\(isPresented: \$showHeightChart\) \{.*?\n        \}", "", content2, flags=re.DOTALL)
content2 = re.sub(r"\.sheet\(isPresented: \$showWeightChart\) \{.*?\n        \}", "", content2, flags=re.DOTALL)
content2 = re.sub(r"\.sheet\(isPresented: Binding\(get: \{ selectedLiftChartName != nil \}.*?\n        \}", "", content2, flags=re.DOTALL)
content2 = re.sub(r"private func generateFakeData\(.*?return data\n    \}", "", content2, flags=re.DOTALL)

content2 = re.sub(r"@State private var showHeightChart = false\n    @State private var showWeightChart = false\n    @State private var selectedLiftChartName: String\? = nil", 
"""@State private var navToStats: Bool = false
    @State private var initialStatSelection: StatSelection = .height""", content2)

content2 = re.sub(r"Button \{ showHeightChart = true \} label:", "Button { initialStatSelection = .height; navToStats = true } label:", content2)
content2 = re.sub(r"Button \{ showWeightChart = true \} label:", "Button { initialStatSelection = .weight; navToStats = true } label:", content2)
content2 = re.sub(r"Button \{ selectedLiftChartName = lift.name \} label:", "Button { initialStatSelection = .lift(lift.name); navToStats = true } label:", content2)

# ProfileView is wrapped in a NavigationStack in MainTabView. But does it have a NavigationStack inside itself?
# Let's just attach navigationDestination to the ZStack.
content2 = re.sub(r"        ZStack \{\n", 
"""        ZStack {
""", content2)

# We will put the navigationDestination right after ScrollView or ZStack.
# Wait, ProfileView doesn't have a specific end anchor. Let's just append it to the ZStack using a regex that finds the last brace before the struct ends.
content2 = re.sub(r"    \}\n\}\n*$", 
"""    }
    .navigationDestination(isPresented: $navToStats) {
        StatsView(username: viewModel.username, heightStr: viewModel.height, weightStr: viewModel.weight, lifts: viewModel.proudestLifts, selection: initialStatSelection)
    }
}
""", content2, flags=re.MULTILINE)

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
    f.write(content2)

print("Patched both views!")
