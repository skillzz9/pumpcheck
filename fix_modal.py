import re

with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "r") as f:
    content = f.read()

# Replace the Button block
old_button = r"""                        Button \{
                            showCropModal = true
                        \} label: \{
                            Color\.clear
                                \.contentShape\(Rectangle\(\)\)
                                \.aspectRatio\(9\.0 / 16\.0, contentMode: \.fit\)
                                \.overlay\(
                                    GeometryReader \{ geo in
                                        ZStack \{
                                            Theme\.pitchBlack
                                            Image\(uiImage: uiImage\)
                                                \.resizable\(\)
                                                \.scaledToFill\(\)
                                                \.offset\(offset\)
                                                \.scaleEffect\(scale\)
                                                \.frame\(width: geo\.size\.width, height: geo\.size\.height\)
                                        \}
                                        \.frame\(width: geo\.size\.width, height: geo\.size\.height\)
                                        \.clipped\(\)
                                        \.onAppear \{ cropSize = geo\.size \}
                                        \.onChange\(of: geo\.size\) \{ _, newSize in cropSize = newSize \}
                                    \}
                                \)
                                \.cornerRadius\(16\)
                                \.overlay\(RoundedRectangle\(cornerRadius: 16\)\.stroke\(Theme\.accent, lineWidth: 2\)\)
                                \.overlay\(
                                    VStack \{
                                        Image\(systemName: "crop"\)
                                            \.font\(\.system\(size: 30\)\)
                                        Text\("Tap to Crop"\)
                                            \.font\(\.headline\)
                                    \}
                                    \.foregroundColor\(\.white\)
                                    \.padding\(\)
                                    \.background\(Color\.black\.opacity\(0\.6\)\)
                                    \.cornerRadius\(12\)
                                \)
                                \.padding\(\.horizontal, 64\)
                        \}
                        \.padding\(\.top, 24\)"""

new_button = """                        Button {
                            showCropModal = true
                        } label: {
                            ZStack {
                                Theme.pitchBlack
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .offset(offset)
                                    .scaleEffect(scale)
                            }
                            .aspectRatio(9.0 / 16.0, contentMode: .fit)
                            .clipped()
                            .overlay(
                                GeometryReader { geo in
                                    Color.clear
                                        .onAppear { cropSize = geo.size }
                                        .onChange(of: geo.size) { _, newSize in cropSize = newSize }
                                }
                            )
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 2))
                            .overlay(
                                VStack {
                                    Image(systemName: "crop")
                                        .font(.system(size: 30))
                                    Text("Tap to Crop")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(12)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 64)
                        .padding(.top, 24)"""

content = re.sub(old_button, new_button, content)

with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "w") as f:
    f.write(content)

