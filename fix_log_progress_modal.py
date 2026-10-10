import sys

with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "r") as f:
    content = f.read()

# Add states for crop
old_states = """    @State private var newLifts: [LiftRecord] = []
    @State private var selectedDate = Date()"""

new_states = """    @State private var newLifts: [LiftRecord] = []
    @State private var selectedDate = Date()
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var cropSize: CGSize = .zero"""

content = content.replace(old_states, new_states)

# Replace Image Preview UI
old_preview = """                        // Image Preview
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 2))
                            .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                            .padding(.top, 24)"""

new_preview = """                        // Image Preview (4:5 Cropper)
                        Color.clear
                            .aspectRatio(4.0 / 5.0, contentMode: .fit)
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
                            .padding(.top, 24)"""

content = content.replace(old_preview, new_preview)

# Update saveProgress to use ImageRenderer
old_save = """    func saveProgress() {
        guard let data = uiImage.jpegData(compressionQuality: 0.1) else { return }
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

content = content.replace(old_save, new_save)

# We must ensure the 'Save' button is called in a Task or MainActor since saveProgress is now @MainActor.
# Let's check how saveProgress is called. 
# It's called in a Button action. Button actions run on MainActor anyway.

with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "w") as f:
    f.write(content)

