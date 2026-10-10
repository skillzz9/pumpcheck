import sys

with open("PumpCheck.swiftpm/Onboarding/TestScoringView.swift", "r") as f:
    content = f.read()

old_error_ui = """                        if let error = errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                        }"""

new_error_ui = """                        if let error = errorMessage {
                            VStack(spacing: 8) {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                                    .textSelection(.enabled)
                                
                                Button(action: {
                                    UIPasteboard.general.string = error
                                }) {
                                    Text("Copy Error")
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Theme.cardBackground)
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                        }"""

content = content.replace(old_error_ui, new_error_ui)

with open("PumpCheck.swiftpm/Onboarding/TestScoringView.swift", "w") as f:
    f.write(content)

