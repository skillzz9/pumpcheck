import re

with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "r") as f:
    content = f.read()

# Add the state variables for cropping
if "showCropModal" not in content:
    state_vars = """    @State private var newLifts: [LiftRecord] = []
    @State private var selectedDate: Date = Date()
    @State private var showCropModal: Bool = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var cropSize: CGSize = CGSize(width: 300, height: 533) # 9:16 ratio default"""
    
    content = re.sub(r'    @State private var newLifts: \[LiftRecord\] = \[\]\n    @State private var selectedDate: Date = Date\(\)', state_vars, content)

# Replace the Image Preview block
old_preview = r"""                        // Image Preview
                        Image\(uiImage: uiImage\)
                            \.resizable\(\)
                            \.scaledToFill\(\)
                            \.frame\(width: 150, height: 150\)
                            \.clipShape\(RoundedRectangle\(cornerRadius: 16\)\)
                            \.overlay\(RoundedRectangle\(cornerRadius: 16\)\.stroke\(Theme\.accent, lineWidth: 2\)\)
                            \.shadow\(color: Theme\.accent\.opacity\(0\.3\), radius: 10, x: 0, y: 5\)
                            \.padding\(\.top, 24\)"""

new_preview = """                        // Image Preview
                        Button {
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
                            .frame(width: 150, height: 150 * (16.0 / 9.0)) // Small 9:16 preview box!
                            .clipped()
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 2))
                            .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                            .overlay(
                                VStack {
                                    Image(systemName: "crop")
                                        .font(.system(size: 24))
                                    Text("Crop")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 24)"""

if "showCropModal = true" not in content:
    content = re.sub(old_preview, new_preview, content)

# Add the ImageCropperModal struct at the end
cropper_struct = """
struct ImageCropperModal: View {
    var uiImage: UIImage
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var lastScale: CGFloat
    @Binding var lastOffset: CGSize
    @Binding var cropSize: CGSize
    var onDone: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.pitchBlack.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Color.clear
                        .aspectRatio(9.0 / 16.0, contentMode: .fit)
                        .overlay(
                            GeometryReader { geo in
                                ZStack {
                                    Theme.pitchBlack
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .offset(offset)
                                        .scaleEffect(scale)
                                        .gesture(
                                            SimultaneousGesture(
                                                MagnificationGesture()
                                                    .onChanged { val in scale = max(1.0, lastScale * val) }
                                                    .onEnded { val in lastScale = scale },
                                                DragGesture()
                                                    .onChanged { val in 
                                                        offset = CGSize(
                                                            width: lastOffset.width + val.translation.width,
                                                            height: lastOffset.height + val.translation.height
                                                        )
                                                    }
                                                    .onEnded { val in lastOffset = offset }
                                            )
                                        )
                                }
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .onAppear { cropSize = geo.size }
                                .onChange(of: geo.size) { _, newSize in cropSize = newSize }
                            }
                        )
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 2))
                        .padding(.horizontal, 24)
                    
                    // Zoom Slider for Simulator
                    HStack {
                        Image(systemName: "minus.magnifyingglass").foregroundColor(Theme.taupeGrey)
                        Slider(value: Binding(get: { scale }, set: { val in scale = val; lastScale = val }), in: 1.0...5.0).tint(Theme.accent)
                        Image(systemName: "plus.magnifyingglass").foregroundColor(Theme.taupeGrey)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("Crop & Align")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.pitchBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDone()
                    }
                    .foregroundColor(Theme.accent)
                    .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }
}
"""

if "ImageCropperModal" not in content:
    content = content + cropper_struct
    
# Append fullScreenCover modifier before the end of LogProgressModal
full_screen_cover = """        .fullScreenCover(isPresented: $showCropModal) {
            ImageCropperModal(
                uiImage: uiImage,
                scale: $scale,
                offset: $offset,
                lastScale: $lastScale,
                lastOffset: $lastOffset,
                cropSize: $cropSize,
                onDone: { showCropModal = false }
            )
        }
    }
    
    @MainActor
"""
if "fullScreenCover" not in content:
    content = content.replace("    }\n    \n    @MainActor", full_screen_cover)

# Replace the save logic to use cropSize and ImageRenderer
old_save = """    @MainActor
    func saveProgress() {
        guard let data = uiImage.jpegData(compressionQuality: 0.2) else { return }
        let base64 = data.base64EncodedString()"""
        
new_save = """    @MainActor
    func saveProgress() {
        // Generate cropped image
        let cropView = ZStack {
            Theme.pitchBlack
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .offset(offset)
                .scaleEffect(scale)
                .frame(width: cropSize.width, height: cropSize.height)
        }
        .frame(width: cropSize.width, height: cropSize.height)
        .clipped()
        
        let renderer = ImageRenderer(content: cropView)
        renderer.scale = UIScreen.main.scale
        
        guard let finalImage = renderer.uiImage,
              let data = finalImage.jpegData(compressionQuality: 0.2) else { return }
        
        let base64 = data.base64EncodedString()"""

if "ImageRenderer(content: cropView)" not in content:
    content = content.replace(old_save, new_save)


with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "w") as f:
    f.write(content)

