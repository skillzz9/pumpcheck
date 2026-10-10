import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

old_fetch = """            for doc in snapshot.documents {
                let data = doc.data()
                let id = data["id"] as? String ?? doc.documentID
                let userId = data["userId"] as? String ?? \"\""""

new_fetch = """            for doc in snapshot.documents {
                let data = doc.data()
                let id = data["id"] as? String ?? doc.documentID
                let userId = data["userId"] as? String ?? \"\"
                
                if viewModel.blockedUsers.contains(userId) {
                    continue
                }"""

content = content.replace(old_fetch, new_fetch)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

