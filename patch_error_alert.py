import re

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "r") as f:
    content = f.read()

# Add State
target_state = """    @State private var commentText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var replyingToId: String? = nil"""
replacement_state = """    @State private var commentText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var replyingToId: String? = nil
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false"""
content = content.replace(target_state, replacement_state)

# Add Alert
target_alert = """        }
        .background(Theme.pitchBlack.ignoresSafeArea())
    }
}"""
replacement_alert = """        }
        .background(Theme.pitchBlack.ignoresSafeArea())
        .alert("Firebase Error", isPresented: $showErrorAlert, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { msg in
            Text(msg)
        }
    }
}"""
content = content.replace(target_alert, replacement_alert)

# Modify Save Logic
target_save = """                    db.collection("posts").document(post.id).setData(["comments": dicts], merge: true) { error in
                        if let error = error {
                            print("Firebase Comment Save Error: \\(error.localizedDescription)")
                            // Fallback to updating the whole post just in case the post was deleted?
                        }
                    }"""
replacement_save = """                    db.collection("posts").document(post.id).setData(["comments": dicts], merge: true) { error in
                        if let error = error {
                            self.errorMessage = error.localizedDescription
                            self.showErrorAlert = true
                        } else {
                            // verify read
                            db.collection("posts").document(post.id).getDocument { doc, err in
                                if let err = err {
                                    self.errorMessage = "Saved, but failed to read back: \\(err.localizedDescription)"
                                    self.showErrorAlert = true
                                }
                            }
                        }
                    }"""
content = content.replace(target_save, replacement_save)

with open("PumpCheck.swiftpm/Onboarding/CommentModalView.swift", "w") as f:
    f.write(content)

print("Patched error alert into CommentModalView")
