import sys

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "r") as f:
    content = f.read()
    
# We might need to import FirebaseAuth in ProfileView if it's not already
if "import FirebaseAuth" not in content:
    content = content.replace("import SwiftUI", "import SwiftUI\nimport FirebaseAuth")

content = content.replace("StatsView(username: viewModel.username", 'StatsView(userId: Auth.auth().currentUser?.uid ?? "", username: viewModel.username')

with open("PumpCheck.swiftpm/Onboarding/ProfileView.swift", "w") as f:
    f.write(content)

with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "r") as f:
    content2 = f.read()

content2 = content2.replace("StatsView(username: username", 'StatsView(userId: userId, username: username')

with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "w") as f:
    f.write(content2)

