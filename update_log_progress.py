import sys

with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "r") as f:
    content = f.read()

# 1. Add state variable
old_state = "    @State private var newLifts: [LiftRecord] = []"
new_state = "    @State private var newLifts: [LiftRecord] = []\n    @State private var selectedDate: Date = Date()"
content = content.replace(old_state, new_state)

# 2. Add DatePicker UI
old_img = """                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 2))
                            .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                            .padding(.top, 24)"""

new_img = """                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 2))
                            .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                            .padding(.top, 24)
                            
                        DatePicker("Date of Photo", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .padding()
                            .background(Theme.cardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)"""
content = content.replace(old_img, new_img)

# 3. Update save logic
old_save = """        let entry = ProgressEntry(
            id: UUID().uuidString,
            date: Date(),
            photoBase64: base64,
            weight: weight,
            lifts: newLifts
        )"""

new_save = """        let entry = ProgressEntry(
            id: UUID().uuidString,
            date: selectedDate,
            photoBase64: base64,
            weight: weight,
            lifts: newLifts
        )"""
content = content.replace(old_save, new_save)

with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "w") as f:
    f.write(content)

