import re

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content = f.read()

target = """    var body: some View {
        ZStack {"""

replacement = """    var body: some View {
        NavigationStack {
            ZStack {"""

content = content.replace(target, replacement)

# Now we need to add the closing brace for NavigationStack.
# We will just replace the end of the file.
target2 = """    .navigationDestination(isPresented: $navToStats) {
        StatsView(username: viewModel.username, heightStr: viewModel.height, weightStr: viewModel.weight, lifts: viewModel.proudestLifts, selection: initialStatSelection)
    }
}"""

replacement2 = """    .navigationDestination(isPresented: $navToStats) {
        StatsView(username: viewModel.username, heightStr: viewModel.height, weightStr: viewModel.weight, lifts: viewModel.proudestLifts, selection: initialStatSelection)
    }
        }
}"""

content = content.replace(target2, replacement2)

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
    f.write(content)

print("Patched ProfileView NavigationStack!")
