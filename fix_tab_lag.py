import re

with open("PumpCheck.swiftpm/Onboarding/MainTabView.swift", "r") as f:
    content = f.read()

target = """            // Main Content Area
            ZStack {
                if selectedTab == 0 {
                    FeedView(viewModel: viewModel)
                        .transition(.opacity)
                } else if selectedTab == 1 {
                    ProgramView(viewModel: viewModel)
                        .transition(.opacity)
                } else if selectedTab == 2 {
                    ProgressTab(viewModel: viewModel)
                        .transition(.opacity)
                } else if selectedTab == 3 {
                    ProfileView(viewModel: viewModel)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: selectedTab)"""

replacement = """            // Main Content Area
            ZStack {
                FeedView(viewModel: viewModel)
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 0)
                    
                ProgramView(viewModel: viewModel)
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 1)
                    
                ProgressTab(viewModel: viewModel)
                    .opacity(selectedTab == 2 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 2)
                    
                ProfileView(viewModel: viewModel)
                    .opacity(selectedTab == 3 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 3)
            }
            .animation(.easeInOut(duration: 0.15), value: selectedTab)"""

content = content.replace(target, replacement)

with open("PumpCheck.swiftpm/Onboarding/MainTabView.swift", "w") as f:
    f.write(content)

print("Fixed tab switching lag!")
