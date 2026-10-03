with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "r") as f:
    content = f.read()

target = """    @State private var caption: String = ""
    @State private var isPosting = false"""

replacement = """    @State private var caption: String = ""
    @State private var isPosting = false
    @State private var errorMessage: String? = nil"""

target2 = """                        // Submit Button
                        Button(action: createPost) {"""

replacement2 = """                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        // Submit Button
                        Button(action: createPost) {"""

target3 = """            } catch {
                print("Error creating post: \\(error.localizedDescription)")
                await MainActor.run {
                    isPosting = false
                }
            }"""

replacement3 = """            } catch {
                print("Error creating post: \\(error.localizedDescription)")
                await MainActor.run {
                    isPosting = false
                    errorMessage = "Firebase Error: \\(error.localizedDescription). Check your Firestore Security Rules!"
                }
            }"""

content = content.replace(target, replacement)
content = content.replace(target2, replacement2)
content = content.replace(target3, replacement3)

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "w") as f:
    f.write(content)
print("Patched CreatePostModalView successfully!")
