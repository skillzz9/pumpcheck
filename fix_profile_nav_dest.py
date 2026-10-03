import re

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content = f.read()

target = """                .padding(.horizontal, 24)
            }

        }
    }
    .navigationDestination(isPresented: $navToStats) {
        StatsView(username: viewModel.username, heightStr: viewModel.height, weightStr: viewModel.weight, lifts: viewModel.proudestLifts, selection: initialStatSelection)
    }
        }
}"""

replacement = """                .padding(.horizontal, 24)
            }
            .navigationDestination(isPresented: $navToStats) {
                StatsView(username: viewModel.username, heightStr: viewModel.height, weightStr: viewModel.weight, lifts: viewModel.proudestLifts, selection: initialStatSelection)
            }
        }
    }
}"""

if target in content:
    content = content.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
        f.write(content)
    print("Patched successfully!")
else:
    print("Target not found!")
