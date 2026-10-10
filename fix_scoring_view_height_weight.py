import sys

with open("PumpCheck.swiftpm/Onboarding/TestScoringView.swift", "r") as f:
    content = f.read()

# Add viewModel
old_struct = """struct TestScoringView: View {
    @Environment(\\.dismiss) var dismiss
    @State private var selectedItem: PhotosPickerItem? = nil"""

new_struct = """struct TestScoringView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\\.dismiss) var dismiss
    @State private var selectedItem: PhotosPickerItem? = nil"""
content = content.replace(old_struct, new_struct)

# Add Body Fat badge in HStack
old_badges = """                                HStack(spacing: 12) {
                                    VStack(spacing: 4) {
                                        Text("BODY TYPE")"""

new_badges = """                                HStack(spacing: 12) {
                                    VStack(spacing: 4) {
                                        Text("BODY FAT")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.taupeGrey)
                                        Text(res.bodyFatEstimate.uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Theme.cardBackground)
                                    .cornerRadius(8)
                                    
                                    VStack(spacing: 4) {
                                        Text("BODY TYPE")"""
content = content.replace(old_badges, new_badges)

# Pass height and weight to analyzePhysique
old_call = "let res = try await PhysiqueScoringService.shared.analyzePhysique(imageBase64: base64)"
new_call = "let res = try await PhysiqueScoringService.shared.analyzePhysique(imageBase64: base64, height: viewModel.height, weight: viewModel.weight)"
content = content.replace(old_call, new_call)

with open("PumpCheck.swiftpm/Onboarding/TestScoringView.swift", "w") as f:
    f.write(content)

