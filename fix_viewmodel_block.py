import sys

with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "r") as f:
    content = f.read()

# 1. Add blockedUsers property
old_kudos = "    var kudos: Int = 0"
new_kudos = "    var kudos: Int = 0\n    var blockedUsers: [String] = []"
content = content.replace(old_kudos, new_kudos)

# 2. Fetch blockedUsers in fetchUserData
old_fetch = "            self.kudos = data[\"kudos\"] as? Int ?? 0"
new_fetch = "            self.kudos = data[\"kudos\"] as? Int ?? 0\n            self.blockedUsers = data[\"blockedUsers\"] as? [String] ?? []"
content = content.replace(old_fetch, new_fetch)

with open("PumpCheck.swiftpm/Onboarding/OnboardingViewModel.swift", "w") as f:
    f.write(content)

