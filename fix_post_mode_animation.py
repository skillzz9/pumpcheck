import sys

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "r") as f:
    content = f.read()

old_conditional = """                        if postMode == .single {
                            singleModeView
                        } else {
                            progressModeView
                        }"""

new_conditional = """                        ZStack(alignment: .top) {
                            if postMode == .single {
                                singleModeView
                                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
                            } else {
                                progressModeView
                                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                            }
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: postMode)"""

content = content.replace(old_conditional, new_conditional)

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "w") as f:
    f.write(content)

