import sys

with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "r") as f:
    content = f.read()

# Add sheet state
if "@State private var showScoringTest = false" not in content:
    old_state = "@State private var showBetaAlert = false"
    new_state = "@State private var showBetaAlert = false\n    @State private var showScoringTest = false"
    content = content.replace(old_state, new_state)

# Add Test Score Button
old_btn = """                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        Text("Only 50 spots available for the first beta wave.")"""

new_btn = """                        .padding(.horizontal, 24)
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
                        
                        Text("Only 50 spots available for the first beta wave.")"""

content = content.replace(old_btn, new_btn)

# Add sheet modifier
old_sheet = """        .alert("Joined Waitlist!", isPresented: $showBetaAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You're on the list for early access. We'll notify you when your spot is ready.")
        }"""

new_sheet = """        .alert("Joined Waitlist!", isPresented: $showBetaAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You're on the list for early access. We'll notify you when your spot is ready.")
        }
        .sheet(isPresented: $showScoringTest) {
            TestScoringView()
        }"""

content = content.replace(old_sheet, new_sheet)

with open("PumpCheck.swiftpm/Onboarding/ProgramView.swift", "w") as f:
    f.write(content)

