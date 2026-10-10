with open("PumpCheck.swiftpm/Onboarding/PublicProfileView.swift", "r") as f:
    text = f.read()

import re
# Check how many braces are missing before .navigationTitle
# We can just count { and } from start to private func fetchPublicProfile
