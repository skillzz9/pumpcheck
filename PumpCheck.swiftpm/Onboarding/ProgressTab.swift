import SwiftUI
import PhotosUI
import ImageIO

struct ProgressEntry: Identifiable, Codable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var photoBase64: String
    var weight: String
    var lifts: [LiftRecord]
    var coverage: [Double]? = nil // See ProgressCoverage
}

struct ProgressTab: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var sliderValue: Double = 0
    @AppStorage(ProgressSliderMode.storageKey) private var sliderMode: ProgressSliderMode = .flicker
    @State private var selectedImageData: Data? = nil
    @State private var showLogModal = false
    @State private var isProcessingPhoto = false
    @State private var selectedEntry: ProgressEntry? = nil
    @State private var showAccuracyWarning = false
    @State private var openCameraAfterWarning = false
    @State private var showCamera = false
    @State private var capturedPhoto: UIImage? = nil
    
    static let plusSize: CGFloat = 40
    
    /// Entries with a photo, oldest first by the date the photo was taken (not when it was uploaded).
    /// Weight-only check-ins feed the weight graph but have nothing to show here.
    private var photoEntries: [ProgressEntry] {
        viewModel.progressEntries.filter { !$0.photoBase64.isEmpty }.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    // New Large Photo Slider
                    let sortedEntries = photoEntries.sorted(by: { $0.date < $1.date })
                    if !sortedEntries.isEmpty {
                        VStack(spacing: 0) {
                            let currentIndex = min(max(Int(round(sliderValue)), 0), sortedEntries.count - 1)
                            let currentEntry = sortedEntries[currentIndex]
                            
                            ProgressPhotoStack(photos: sortedEntries.map(\.photoBase64), sliderValue: sliderValue, mode: sliderMode,
                                               crop: ProgressCoverage.commonCrop(sortedEntries.map(\.coverage)))
                                .overlay(alignment: .topLeading) {
                                    if sortedEntries.count > 1 {
                                        ProgressSliderModeToggle(mode: $sliderMode)
                                    }
                                }
                            
                            if sortedEntries.count > 1 {
                                VStack(spacing: 8) {
                                    GeometryReader { geo in
                                        let trackWidth = geo.size.width - 28
                                        let percentage = CGFloat(sliderValue / Double(sortedEntries.count - 1))
                                        let thumbX = 14 + (percentage * trackWidth)
                                        
                                        Text(currentEntry.date.formatted(.dateTime.year().month().day()))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.taupeGrey)
                                            .position(x: thumbX, y: geo.size.height / 2)
                                    }
                                    .frame(height: 14)
                                    
                                    Slider(value: $sliderValue, in: 0...Double(sortedEntries.count - 1), onEditingChanged: { editing in
                                        if !editing && sliderMode == .flicker {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                sliderValue = round(sliderValue)
                                            }
                                        }
                                    })
                                    .tint(Theme.accent)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Theme.pitchBlack)
                                .task(id: sortedEntries.count) {
                                    await DemoMode.autoSlide(photoCount: sortedEntries.count) { sliderValue = $0 }
                                }
                            } else {
                                Text(currentEntry.date.formatted(.dateTime.year().month().day()))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.taupeGrey)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.pitchBlack)
                            }
                        }
                        .padding(.bottom, 0)
                    }
                    
                    // The .onChange for uploading photo must be attached somewhere.
                    // We'll attach it to the VStack or ScrollView below.
                    EmptyView()
                        .onChange(of: selectedItem) { _, newItem in
                    guard let newItem = newItem else { return }
                    isProcessingPhoto = true
                    Task {
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    selectedImageData = data
                                    isProcessingPhoto = false
                                    showLogModal = true
                                }
                            } else {
                                await MainActor.run { isProcessingPhoto = false }
                            }
                        } catch {
                            await MainActor.run { isProcessingPhoto = false }
                        }
                    }
                }
                
                // Same shared crop as the slider, so the thumbnails have no black borders either
                let diaryCrop = ProgressCoverage.commonCrop(photoEntries.map(\.coverage))
                
                VStack(alignment: .leading, spacing: 12) {
                    if !photoEntries.isEmpty {
                        Text("Diary")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                    }
                    
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(photoEntries.reversed()) { entry in
                            Button(action: {
                                selectedEntry = entry
                            }) {
                                ZStack(alignment: .bottomLeading) {
                                    if let uiImage = ImageCache.decode(base64: entry.photoBase64) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .aspectRatio(9.0 / 16.0, contentMode: .fit)
                                            .scaleEffect(1 / diaryCrop.scale, anchor: diaryCrop.anchor)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Theme.cardBackground)
                                            .aspectRatio(9.0 / 16.0, contentMode: .fit)
                                    }
                                    
                                    LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .center)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.date.formatted(.dateTime.day().month()))
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        if !entry.weight.isEmpty {
                                            Text("\(entry.weight)\(viewModel.isWeightKg ? "kg" : "lb")")
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundColor(Theme.accent)
                                        }
                                    }
                                    .padding(8)
                                }
                            }
                        }
                    }
                }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }

            if photoEntries.isEmpty {
                EmptyProgressHint()
                    .allowsHitTesting(false) // Taps go through to the + button
            }
            
            // Floating + over the content; its center matches EmptyProgressHint.plusCenter so the arrow points at it
            Group {
                if isProcessingPhoto {
                    ProgressView()
                        .tint(Theme.pitchBlack)
                        .frame(width: Self.plusSize, height: Self.plusSize)
                        .background(Theme.accent)
                        .clipShape(Circle())
                } else {
                    Button {
                        showAccuracyWarning = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Theme.pitchBlack)
                            .frame(width: Self.plusSize, height: Self.plusSize)
                            .background(Theme.accent)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
            }
            // Level with the Flicker/Fade toggle (10pt inset, ~25pt tall), mirrored on the right
            .padding(.top, 23 - Self.plusSize / 2)
            .padding(.trailing, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .sheet(isPresented: $showAccuracyWarning, onDismiss: {
            // The camera can only open once this sheet has finished closing
            if openCameraAfterWarning {
                openCameraAfterWarning = false
                showCamera = true
            }
        }) {
            AccuracyWarningModal(selectedItem: $selectedItem, onTakePhoto: { openCameraAfterWarning = true })
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            // Same path as a library photo: a camera shot has no EXIF date, so it's logged as today
            if let capturedPhoto, let data = capturedPhoto.jpegData(compressionQuality: 0.9) {
                selectedImageData = data
                showLogModal = true
            }
            capturedPhoto = nil
        }) {
            CameraPicker { image in capturedPhoto = image }
                .ignoresSafeArea()
        }
        .sheet(item: $selectedEntry) { entry in
            ProgressDetailView(
                initialEntry: entry,
                allEntries: photoEntries,
                isWeightKg: viewModel.isWeightKg,
                onDismiss: { selectedEntry = nil },
                onDelete: { try await viewModel.deleteProgressEntry($0) }
            )
        }
        .sheet(isPresented: $showLogModal) {
            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                LogProgressModal(
                    viewModel: viewModel,
                    uiImage: uiImage,
                    initialDate: extractDate(from: data) ?? Date(),
                    onSave: {
                        selectedItem = nil
                        selectedImageData = nil
                        showLogModal = false
                    },
                    onCancel: {
                        selectedItem = nil
                        selectedImageData = nil
                        showLogModal = false
                    }
                )
            }
        }
    }
}


/// Empty state: a centered message with a hand-drawn arrow curving up to the + button in the header.
struct EmptyProgressHint: View {
    @State private var drawn: CGFloat = 0

    // Center of ProgressTab's floating + button
    private static let plusCenter = CGPoint(x: -(10 + ProgressTab.plusSize / 2), y: 23) // x measured from the trailing edge

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let start = CGPoint(x: center.x + 70, y: center.y - 70)
            let tip = CGPoint(x: geo.size.width + Self.plusCenter.x, y: Self.plusCenter.y + 30)

            ZStack {
                HandDrawnArrow(start: start, tip: tip)
                    .trim(from: 0, to: drawn)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))

                Text("Upload your first progress picture by clicking the plus button")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(width: min(geo.size.width - 64, 300))
                    .position(x: center.x, y: center.y + 10)
            }
        }
        .task {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) { drawn = 1 }
        }
    }
}

/// A loose arrow from `start` up to `tip`: a smooth arc ending in a two-stroke head.
struct HandDrawnArrow: Shape {
    let start: CGPoint
    let tip: CGPoint

    func path(in rect: CGRect) -> Path {
        let dx = tip.x - start.x
        let dy = tip.y - start.y
        func p(_ fx: CGFloat, _ fy: CGFloat) -> CGPoint { CGPoint(x: start.x + fx * dx, y: start.y + fy * dy) }

        var path = Path()
        path.move(to: start)
        // One smooth arc: bow out to the left, then sweep up into the tip
        let lastControl = p(0.95, 0.4)
        path.addCurve(to: tip, control1: p(-0.15, 0.55), control2: lastControl)

        // Arrowhead along the final direction of travel
        let angle = atan2(tip.y - lastControl.y, tip.x - lastControl.x)
        let length: CGFloat = 16
        for spread in [CGFloat.pi * 0.8, -CGFloat.pi * 0.78] {
            path.move(to: tip)
            path.addLine(to: CGPoint(x: tip.x + length * cos(angle + spread), y: tip.y + length * sin(angle + spread)))
        }
        return path
    }
}

struct AccuracyWarningModal: View {
    @Binding var selectedItem: PhotosPickerItem?
    var onTakePhoto: () -> Void = {}
    @Environment(\.dismiss) var dismiss
    
    private let hasCamera = UIImagePickerController.isSourceTypeAvailable(.camera)
    
    /// How long the button takes to fill, so people read the steps before continuing.
    private static let readingTime: Double = 4
    @State private var fill: CGFloat = 0
    @State private var isReady = false
    
    private static let steps: [(icon: String, title: String, detail: String)] = [
        ("house.fill", "Same room, same lighting", "Face the light, at the same time of day."),
        ("iphone", "Same phone height", "Prop your phone up at chest height. Don't hold it."),
        ("ruler.fill", "Same distance", "About 2 m (6 ft) away. Mark the spot on the floor."),
        ("camera.fill", "Back camera at 1×, with a timer", "No mirror selfies or 0.5×. They warp your body."),
        ("figure.stand", "Stand tall, head level", "Look straight at the camera, arms relaxed, no flexing."),
        ("tshirt.fill", "Same shorts", "Wear them at the same height on your waist.")
    ]
    
    var body: some View {
        ZStack {
            Theme.pitchBlack.ignoresSafeArea()
            
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "camera.metering.spot")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.accent)
                    
                    Text("Consistency is Key")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Text("Set up every photo the same way so you can see your real progress.")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.pitchBlack)
                                .frame(width: 26, height: 26)
                                .background(Theme.accent)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.title)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                Text(step.detail)
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                // The main button fills over the reading time; the library option unlocks with it
                if hasCamera {
                    Button {
                        onTakePhoto()
                        dismiss()
                    } label: {
                        fillingButtonLabel("Take Photo")
                    }
                    .disabled(!isReady)
                    
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        Text("Choose from Library")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(isReady ? Theme.accent : Theme.textSecondary.opacity(0.5))
                    }
                    .disabled(!isReady)
                    .padding(.top, -8)
                } else {
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        fillingButtonLabel("I understand")
                    }
                    .disabled(!isReady)
                }
                
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Theme.textSecondary)
                .padding(.top, -8)
            }
            .padding(.vertical, 24)
        }
        .presentationDetents([.large])
        .onChange(of: selectedItem) { _, newItem in
            if newItem != nil {
                dismiss()
            }
        }
        .task {
            withAnimation(.linear(duration: Self.readingTime)) { fill = 1 }
            try? await Task.sleep(for: .seconds(Self.readingTime))
            withAnimation(.easeOut(duration: 0.25)) { isReady = true }
        }
    }
    
    /// Dim button that fills with the accent color from left to right, then becomes tappable.
    private func fillingButtonLabel(_ title: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.accent.opacity(0.2))
            
            GeometryReader { geo in
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: geo.size.width * fill)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(isReady ? Theme.pitchBlack : Theme.textPrimary.opacity(0.6))
        }
        .frame(height: 54)
        .shadow(color: Theme.accent.opacity(isReady ? 0.4 : 0), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 32)
    }
}

func extractDate(from data: Data) -> Date? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    guard let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else { return nil }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
    
    if let exif = metadata["{Exif}"] as? [String: Any],
       let dateTimeOriginal = exif["DateTimeOriginal"] as? String {
        return formatter.date(from: dateTimeOriginal)
    }
    
    if let tiff = metadata["{TIFF}"] as? [String: Any],
       let dateTime = tiff["DateTime"] as? String {
        return formatter.date(from: dateTime)
    }
    
    return nil
}
