import sys

with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "r") as f:
    content = f.read()

# Add sheet state if not there
if "@State private var showScoringTest = false" not in content:
    content = content.replace("@State private var isCheckingStatus = true", "@State private var isCheckingStatus = true\n    @State private var showScoringTest = false")

old_btn = """                        .disabled(isSignedUp || isUpdating || isCheckingStatus)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 40)"""

new_btn = """                        .disabled(isSignedUp || isUpdating || isCheckingStatus)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        Button(action: { showScoringTest = true }) {
                            Text("Test AI Score")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.cardBackground)
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 1))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        
                        Spacer(minLength: 40)"""

content = content.replace(old_btn, new_btn)

# Add sheet modifier if not there
if ".sheet(isPresented: $showScoringTest)" not in content:
    old_nav = """            .navigationTitle("Program")"""
    new_nav = """            .sheet(isPresented: $showScoringTest) {
                TestScoringView()
            }
            .navigationTitle("Program")"""
    content = content.replace(old_nav, new_nav)

with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "w") as f:
    f.write(content)

