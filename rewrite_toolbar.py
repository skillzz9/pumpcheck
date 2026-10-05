import sys

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

old_toolbar = """            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {"""

new_toolbar = """            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            let db = Firestore.firestore()
                            if let snap = try? await db.collection("posts").getDocuments() {
                                for doc in snap.documents {
                                    try? await db.collection("posts").document(doc.documentID).delete()
                                }
                            }
                            await fetchPosts()
                        }
                    }) {
                        Text("Clear All")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {"""

content = content.replace(old_toolbar, new_toolbar)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

