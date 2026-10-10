import SwiftUI

struct LogProgressModal: View {
    @Bindable var viewModel: OnboardingViewModel
    let uiImage: UIImage
    var initialDate: Date
    var onSave: () -> Void
    var onCancel: () -> Void
    
    @State private var weight: String = ""
    @State private var newLifts: [LiftRecord] = []
    @State private var customDate: Date = Date()
    
    // Image Cropper State
    @State private var showCropModal = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero
    @State private var cropSize: CGSize = .zero
    @State private var isSaving = false
    @State private var saveError: String? = nil

    var weightPercentChange: Double? {
        let cleanOld = viewModel.weight.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNew = weight.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let oldW = Double(cleanOld),
              let newW = Double(cleanNew),
              oldW > 0 else { return nil }
        return ((newW - oldW) / oldW) * 100.0
    }

    var previousImage: UIImage? {
        let sortedEntries = viewModel.progressEntries.filter { !$0.photoBase64.isEmpty }.sorted(by: { $0.date < $1.date })
        if let lastEntry = sortedEntries.last {
            return ImageCache.decode(base64: lastEntry.photoBase64)
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image Preview
                        Button {
                            showCropModal = true
                        } label: {
                            ZStack {
                                Theme.pitchBlack
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .offset(
                                        x: offset.width * (cropSize.width > 0 ? 150.0 / cropSize.width : 1.0),
                                        y: offset.height * (cropSize.height > 0 ? (150.0 * (16.0 / 9.0)) / cropSize.height : 1.0)
                                    )
                                    .scaleEffect(scale)
                                    .rotationEffect(rotation)
                            }
                            .frame(width: 150, height: 150 * (16.0 / 9.0))
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
                        .padding(.top, 24)
                        
                        // Optional Weight
                        VStack(spacing: 8) {
                            HStack {
                                Text("Current Weight")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                
                                Spacer()
                                
                                if !viewModel.weight.isEmpty {
                                    Text(viewModel.weight)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)
                                    
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(Theme.accent)
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.horizontal, 4)
                                }
                                
                                TextField("New", text: $weight)
                                    .keyboardType(.decimalPad)
                                    .padding(12)
                                    .frame(width: 80)
                                    .background(Theme.textBoxBlue)
                                    .cornerRadius(12)
                                    .foregroundColor(Theme.textPrimary)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1))
                                
                                Text(viewModel.isWeightKg ? "kg" : "lbs")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textSecondary)
                                    .padding(.leading, 4)
                            }
                            
                            if let inc = weightPercentChange {
                                HStack {
                                    Image(systemName: inc >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    Text(String(format: "%.1f%% %@", abs(inc), inc >= 0 ? "increase" : "decrease"))
                                }
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(inc >= 0 ? .green : .red)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        
                        // Lifts
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Update Lifts")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal, 24)
                            
                            ForEach($newLifts) { $lift in
                                LiftUpdateRow(lift: $lift, oldLifts: viewModel.proudestLifts)
                            }
                            
                            Button(action: {
                                newLifts.append(LiftRecord(name: "", weight: 0, reps: 0))
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Another Lift")
                                }
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.accent)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Theme.textBoxBlue)
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Custom Date Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                            
                            DatePicker("Select Date", selection: $customDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .colorScheme(.dark)
                                .labelsHidden()
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Log Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancel() }
                        .foregroundColor(Theme.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView().tint(Theme.accent)
                    } else {
                        Button("Save") { saveProgress() }
                            .fontWeight(.bold)
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .onAppear {
                customDate = initialDate
                // Initialize with established lifts
                newLifts = viewModel.proudestLifts
                // If they have no established lifts, start with one empty one
                if newLifts.isEmpty {
                    newLifts.append(LiftRecord(name: "", weight: 0, reps: 0))
                }
            }
            .alert("Couldn't save", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "")
            }
            .sheet(isPresented: $showCropModal) {
                ImageCropperModal(
                    uiImage: uiImage,
                    previousImage: previousImage,
                    scale: $scale,
                    offset: $offset,
                    lastScale: $lastScale,
                    lastOffset: $lastOffset,
                    rotation: $rotation,
                    lastRotation: $lastRotation,
                    cropSize: $cropSize
                ) {
                    showCropModal = false
                }
            }
        }
    }
    
    @MainActor
    func saveProgress() {
        // Render the image exactly as cropped, at a high resolution (1080 width, 9:16 aspect)
        let renderWidth: CGFloat = 1080
        let renderHeight: CGFloat = renderWidth * (16.0 / 9.0)
        
        let multX = cropSize.width > 0 ? renderWidth / cropSize.width : 1.0
        let multY = cropSize.height > 0 ? renderHeight / cropSize.height : 1.0
        
        let viewToRender = ZStack {
            Color.black
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .offset(x: offset.width * multX, y: offset.height * multY)
                .scaleEffect(scale)
                .rotationEffect(rotation)
        }
        .frame(width: renderWidth, height: renderHeight)
        .clipped()
        
        let renderer = ImageRenderer(content: viewToRender)
        renderer.scale = 1.0
        
        guard let finalImage = renderer.uiImage,
              let data = finalImage.jpegData(compressionQuality: 0.5) else {
            saveError = "Couldn't process the photo. Open Crop, check the alignment and try again."
            return
        }
              
        let base64 = data.base64EncodedString()
        
        let entry = ProgressEntry(
            id: UUID().uuidString,
            date: customDate,
            photoBase64: base64,
            weight: weight,
            lifts: newLifts,
            coverage: ProgressCoverage.coverage(imageSize: uiImage.size, frameSize: cropSize, scale: scale, offset: offset, rotation: rotation)
        )
        isSaving = true
        Task {
            do {
                try await viewModel.saveProgressEntry(entry)
            } catch {
                isSaving = false
                saveError = error.localizedDescription
                return
            }
            viewModel.setProfilePhotoIfMissing(from: finalImage)
            finishSave()
        }
    }
    
    /// Updates profile stats from the saved entry, then closes the sheet.
    private func finishSave() {
        // Update main profile stats
        var didUpdateStats = false
        if !weight.isEmpty && viewModel.weight != weight {
            viewModel.weight = weight
            didUpdateStats = true
        }
        for newLift in newLifts where newLift.weight > 0 && newLift.reps > 0 && !newLift.name.isEmpty {
            if let index = viewModel.proudestLifts.firstIndex(where: { $0.name.lowercased() == newLift.name.lowercased() }) {
                if viewModel.proudestLifts[index].weight != newLift.weight || viewModel.proudestLifts[index].reps != newLift.reps {
                    viewModel.proudestLifts[index] = newLift
                    didUpdateStats = true
                }
            } else {
                viewModel.proudestLifts.append(newLift)
                didUpdateStats = true
            }
        }
        
        if didUpdateStats {
            viewModel.syncProfileStatsToFirebase()
        }
        
        onSave()
    }
}

struct LiftUpdateRow: View {
    @Binding var lift: LiftRecord
    let oldLifts: [LiftRecord]
    
    // Create temporary string states for the TextFields to handle decimals properly
    @State private var weightStr: String = ""
    @State private var repsStr: String = ""
    
    var oldLift: LiftRecord? {
        oldLifts.first(where: { $0.name.lowercased() == lift.name.lowercased() })
    }
    
    var percentIncrease: Double? {
        guard let old = oldLift, old.weight > 0, old.reps > 0 else { return nil }
        guard lift.weight > 0, lift.reps > 0 else { return nil }
        
        // Use Epley formula for 1 Rep Max estimation: 1RM = W * (1 + R/30)
        let old1RM = old.weight * (1.0 + Double(old.reps) / 30.0)
        let new1RM = lift.weight * (1.0 + Double(lift.reps) / 30.0)
        
        return ((new1RM - old1RM) / old1RM) * 100.0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Lift Name (e.g. Bench Press)", text: $lift.name)
                .textFieldStyle(PumpTextFieldStyle())
            
            VStack(spacing: 8) {
                // Weight Row
                HStack {
                    Text("Weight")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 60, alignment: .leading)
                    
                    Spacer()
                    
                    if let old = oldLift {
                        Text(old.weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", old.weight) : String(format: "%.1f", old.weight))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(Theme.accent)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 4)
                    }
                    
                    TextField("New", text: $weightStr)
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .frame(width: 80)
                        .background(Theme.textBoxBlue)
                        .cornerRadius(12)
                        .foregroundColor(Theme.textPrimary)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1))
                        .onChange(of: weightStr) { _, newValue in
                            lift.weight = Double(newValue) ?? 0
                        }
                }
                
                // Reps Row
                HStack {
                    Text("Reps")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 60, alignment: .leading)
                    
                    Spacer()
                    
                    if let old = oldLift {
                        Text("\(old.reps)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(Theme.accent)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 4)
                    }
                    
                    TextField("New", text: $repsStr)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .frame(width: 80)
                        .background(Theme.textBoxBlue)
                        .cornerRadius(12)
                        .foregroundColor(Theme.textPrimary)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1))
                        .onChange(of: repsStr) { _, newValue in
                            lift.reps = Int(newValue) ?? 0
                        }
                }
            }
            
            if let inc = percentIncrease {
                HStack {
                    Image(systemName: inc >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(String(format: "%.1f%% %@", abs(inc), inc >= 0 ? "increase" : "decrease"))
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(inc >= 0 ? .green : .red)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal, 24)
        .onAppear {
            weightStr = lift.weight > 0 ? (lift.weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", lift.weight) : String(lift.weight)) : ""
            repsStr = lift.reps > 0 ? String(lift.reps) : ""
        }
    }
}

struct ImageCropperModal: View {
    var uiImage: UIImage
    var previousImage: UIImage?
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var lastScale: CGFloat
    @Binding var lastOffset: CGSize
    @Binding var rotation: Angle
    @Binding var lastRotation: Angle
    @Binding var cropSize: CGSize
    var onDone: () -> Void
    
    @State private var isBlending = false
    @State private var showEyes = true
    
    /// Magnification of the eyes view, so the eye markers are far enough apart to match by finger.
    private static let eyeZoom: CGFloat = 4
    /// Below 1 the photo is smaller than the frame, so close-up photos can still be aligned.
    private static let minScale: CGFloat = 0.3
    private static let maxScale: CGFloat = 8
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.pitchBlack.ignoresSafeArea()
                
                VStack {
                    Picker("View", selection: $showEyes.animation(.easeInOut(duration: 0.3))) {
                        Text("Eyes").tag(true)
                        Text("Full Body").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    Color.clear
                        .aspectRatio(9.0 / 16.0, contentMode: .fit)
                        .overlay(
                            GeometryReader { geo in
                                let zoom = showEyes ? Self.eyeZoom : 1
                                ZStack {
                                    // Photo layers, magnified around the eye line in the eyes view.
                                    // Gestures sit inside the transforms, so drags still track the finger at any zoom.
                                    ZStack {
                                        Theme.pitchBlack
                                        
                                        if isBlending, let prev = previousImage {
                                            Image(uiImage: prev)
                                                .resizable()
                                                .scaledToFill()
                                        }
                                        
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .offset(offset)
                                            .scaleEffect(scale)
                                            .rotationEffect(rotation)
                                            .opacity(isBlending ? 0.5 : 1.0)
                                            .gesture(
                                                SimultaneousGesture(
                                                    SimultaneousGesture(
                                                        MagnificationGesture()
                                                            .onChanged { val in setScale(lastScale * val) }
                                                            .onEnded { _ in lastScale = scale },
                                                        RotationGesture()
                                                            .onChanged { val in setRotation(lastRotation + val) }
                                                            .onEnded { _ in lastRotation = rotation }
                                                    ),
                                                    DragGesture()
                                                        .onChanged { val in
                                                            offset = CGSize(
                                                                width: lastOffset.width + val.translation.width,
                                                                height: lastOffset.height + val.translation.height
                                                            )
                                                        }
                                                        .onEnded { _ in lastOffset = offset }
                                                )
                                            )
                                    }
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .scaleEffect(zoom, anchor: EyeGuide.anchor)
                                    
                                    EyeGuide(frameSize: geo.size, zoom: zoom)
                                }
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                // The magnified photo extends far past the frame; without this its
                                // invisible parts swallow taps meant for the buttons and sliders
                                .contentShape(Rectangle())
                                .onAppear { cropSize = geo.size }
                                .onChange(of: geo.size) { _, newSize in cropSize = newSize }
                            }
                        )
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 2))
                        .padding(.horizontal, 24)
                    
                    Text(showEyes
                         ? "Drag, pinch and twist until the centre of each eye sits on a dot"
                         : "Check the framing, then tap Done")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 12)
                    
                    // Fine-tuning sliders (also the only way to zoom and rotate in the Simulator)
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "minus.magnifyingglass").foregroundColor(Theme.taupeGrey)
                            Slider(value: Binding(get: { scale }, set: { val in setScale(val); lastScale = scale }), in: Self.minScale...Self.maxScale).tint(Theme.accent)
                            Image(systemName: "plus.magnifyingglass").foregroundColor(Theme.taupeGrey)
                        }
                        HStack {
                            Image(systemName: "rotate.left").foregroundColor(Theme.taupeGrey)
                            Slider(value: Binding(get: { rotation.degrees }, set: { val in setRotation(.degrees(val)); lastRotation = rotation }), in: -20...20).tint(Theme.accent)
                            Image(systemName: "rotate.right").foregroundColor(Theme.taupeGrey)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    
                    if previousImage != nil {
                        Button(action: {
                            isBlending.toggle()
                        }) {
                            Text(isBlending ? "Turn Blend Off" : "Blend with Previous")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isBlending ? Theme.accent : Theme.textBoxBlue)
                                .foregroundColor(isBlending ? Theme.pitchBlack : Theme.textPrimary)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 16)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Align Eyes")
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

    // MARK: - Zoom and rotate around the eye markers
    //
    // The photo is drawn as offset, then scaled, then rotated about the frame center. To keep the
    // part of the photo under the eye markers fixed, each scale or rotation change also shifts the
    // offset (and lastOffset, so an in-progress drag keeps it).

    /// The eye markers' midpoint, relative to the frame center.
    private var eyePoint: CGPoint {
        CGPoint(x: 0, y: (EyeGuide.eyeY - 0.5) * cropSize.height)
    }

    /// Rotates `point` by -`angle`, undoing the photo's rotation.
    private func unrotate(_ point: CGPoint, by angle: Angle) -> CGPoint {
        let c = CGFloat(cos(angle.radians)), s = CGFloat(sin(angle.radians))
        return CGPoint(x: point.x * c + point.y * s, y: -point.x * s + point.y * c)
    }

    private func shiftOffset(by delta: CGPoint) {
        offset.width += delta.x
        offset.height += delta.y
        lastOffset.width += delta.x
        lastOffset.height += delta.y
    }

    private func setScale(_ newValue: CGFloat) {
        let newScale = min(max(Self.minScale, newValue), Self.maxScale)
        let e = unrotate(eyePoint, by: rotation)
        let k = 1 / newScale - 1 / scale
        shiftOffset(by: CGPoint(x: e.x * k, y: e.y * k))
        scale = newScale
    }

    private func setRotation(_ newValue: Angle) {
        let before = unrotate(eyePoint, by: rotation)
        let after = unrotate(eyePoint, by: newValue)
        shiftOffset(by: CGPoint(x: (after.x - before.x) / scale, y: (after.y - before.y) / scale))
        rotation = newValue
    }
}

/// Two fixed eye markers in the 9:16 crop frame. Putting your eyes on them gives every progress photo
/// the same scale, position and tilt; eye spacing is set by bone, so it doesn't change as you lean out.
/// Spacing assumes eyes ~0.27 of head height and a ~7.5-head body, so the frame shows head to about the knees.
struct EyeGuide: View {
    let frameSize: CGSize
    var zoom: CGFloat = 1

    static let eyeY: CGFloat = 0.12 // of frame height
    static let eyeSpacing: CGFloat = 0.08 // of frame width
    static let anchor = UnitPoint(x: 0.5, y: eyeY)

    var body: some View {
        let y = frameSize.height * Self.eyeY
        // Zooming is centered on the eye line, so only the horizontal spacing grows
        let halfGap = frameSize.width * Self.eyeSpacing / 2 * zoom
        let left = CGPoint(x: frameSize.width / 2 - halfGap, y: y)
        let right = CGPoint(x: frameSize.width / 2 + halfGap, y: y)
        let ring: CGFloat = zoom > 1 ? 18 : 7

        ZStack {
            Path { path in
                path.move(to: left)
                path.addLine(to: right)
            }
            .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            ForEach([left, right], id: \.x) { point in
                ZStack {
                    Circle().stroke(Color.white, lineWidth: 2)
                    Circle().fill(Theme.accent).frame(width: 3, height: 3)
                }
                .frame(width: ring, height: ring)
                .shadow(color: .black.opacity(0.7), radius: 2)
                .position(point)
            }
        }
        .allowsHitTesting(false)
    }
}
