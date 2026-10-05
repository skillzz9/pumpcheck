import re

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "r") as f:
    content = f.read()

# 1. Add state variable
target_state = """    @State private var selectedEntry: ProgressEntry? = nil"""
replacement_state = """    @State private var selectedEntry: ProgressEntry? = nil
    @State private var showAccuracyWarning = false"""
content = content.replace(target_state, replacement_state)

# 2. Replace PhotosPicker with Button
target_picker = """                // Upload button
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {"""
replacement_picker = """                // Upload button
                Button {
                    showAccuracyWarning = true
                } label: {"""
content = content.replace(target_picker, replacement_picker)

# 3. Add .sheet for showAccuracyWarning
target_sheet = """        .sheet(item: $selectedEntry) {"""
replacement_sheet = """        .sheet(isPresented: $showAccuracyWarning) {
            AccuracyWarningModal(selectedItem: $selectedItem)
        }
        .sheet(item: $selectedEntry) {"""
content = content.replace(target_sheet, replacement_sheet)

# 4. Add AccuracyWarningModal struct
modal_struct = """

struct AccuracyWarningModal: View {
    @Binding var selectedItem: PhotosPickerItem?
    @Environment(\\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Theme.pitchBlack.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Image(systemName: "camera.metering.spot")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.accent)
                
                Text("Consistency is Key")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Make sure you take a picture in the same lighting and the same place to make the AI analysis as accurate as possible.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
                
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    Text("I understand")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.pitchBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent)
                        .cornerRadius(16)
                        .padding(.horizontal, 32)
                }
                .onChange(of: selectedItem) { _, newItem in
                    if newItem != nil {
                        dismiss()
                    }
                }
                
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Theme.textSecondary)
                .padding(.top, -8)
            }
        }
        .presentationDetents([.fraction(0.6)])
    }
}
"""

if "struct AccuracyWarningModal" not in content:
    content += modal_struct

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "w") as f:
    f.write(content)

print("Patched ProgressTab successfully!")
