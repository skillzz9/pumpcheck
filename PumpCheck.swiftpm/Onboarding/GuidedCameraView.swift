import SwiftUI
import PhotosUI
import AVFoundation
import AudioToolbox

enum ScanPose: Int, CaseIterable, Hashable {
    case front, side, back

    var title: String {
        switch self {
        case .front: return "Front"
        case .side: return "Side"
        case .back: return "Back"
        }
    }

    var instruction: String {
        switch self {
        case .front:
            return "Face the camera and stand tall, arms relaxed slightly away from your sides. Don't flex or suck in."
        case .side:
            return "Turn to your left so your right side faces the camera. Arms relaxed at your sides, stand tall."
        case .back:
            return "Turn your back to the camera, arms relaxed slightly away from your sides. Don't flex."
        }
    }

    var next: ScanPose? {
        ScanPose(rawValue: rawValue + 1)
    }
}

// MARK: - Camera

final class CameraController: NSObject, ObservableObject {
    enum State { case idle, loading, ready, denied, unavailable }

    @Published private(set) var state: State = .idle
    @Published private(set) var position: AVCaptureDevice.Position = .front

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "com.pumpcheck.camera")
    private var isConfigured = false
    private var completion: ((UIImage?) -> Void)?

    func start() {
        guard state == .idle || state == .denied else { return }
        state = .loading
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { self.configureAndRun() } else { self.state = .denied }
                }
            }
        default:
            state = .denied
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
        if state == .ready || state == .loading { state = .idle }
    }

    func flip() {
        let newPosition: AVCaptureDevice.Position = position == .front ? .back : .front
        queue.async {
            let ok = self.configureInput(newPosition)
            DispatchQueue.main.async {
                if ok { self.position = newPosition }
            }
        }
    }

    func capture(_ completion: @escaping (UIImage?) -> Void) {
        guard state == .ready else { completion(nil); return }
        self.completion = completion
        queue.async {
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }

    private func configureAndRun() {
        let position = self.position
        queue.async {
            if !self.isConfigured {
                self.session.beginConfiguration()
                self.session.sessionPreset = .photo
                if self.session.canAddOutput(self.output) { self.session.addOutput(self.output) }
                self.session.commitConfiguration()
                self.isConfigured = true
            }
            guard self.session.inputs.isEmpty == false || self.configureInput(position) else {
                DispatchQueue.main.async { self.state = .unavailable }
                return
            }
            if !self.session.isRunning { self.session.startRunning() }
            DispatchQueue.main.async { self.state = .ready }
        }
    }

    /// Must be called on `queue`.
    private func configureInput(_ position: AVCaptureDevice.Position) -> Bool {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else { return false }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.inputs.forEach { session.removeInput($0) }
        guard session.canAddInput(input) else { return false }
        session.addInput(input)
        if let connection = output.connection(with: .video), connection.isVideoRotationAngleSupported(90) {
            connection.videoRotationAngle = 90
        }
        return true
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let image = photo.fileDataRepresentation().flatMap { UIImage(data: $0) }
        DispatchQueue.main.async {
            self.completion?(image)
            self.completion = nil
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        override func layoutSubviews() {
            super.layoutSubviews()
            if let connection = previewLayer.connection, connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

// MARK: - Pose outline

/// Body outline in a 3:4 portrait frame: top of head near the top edge, mid-thigh at the bottom.
/// Proportions are based on a ~7.5-head athletic figure.
struct PoseOutline: Shape {
    let pose: ScanPose

    private enum Segment {
        case move(CGFloat, CGFloat)
        case line(CGFloat, CGFloat)
        case curve(CGFloat, CGFloat, control: (CGFloat, CGFloat))
    }

    // Right half of the front/back silhouette; the left half is mirrored.
    private static let frontHalf: [Segment] = [
        .move(0.555, 0.215),
        .line(0.56, 0.255),
        .curve(0.70, 0.285, control: (0.62, 0.265)),
        .curve(0.795, 0.36, control: (0.78, 0.29)),
        .curve(0.83, 0.57, control: (0.82, 0.46)),
        .line(0.84, 0.74),
        .line(0.835, 0.82),
        .curve(0.77, 0.82, control: (0.80, 0.86)),
        .line(0.765, 0.74),
        .line(0.735, 0.57),
        .curve(0.70, 0.40, control: (0.715, 0.47)),
        .curve(0.65, 0.58, control: (0.70, 0.48)),
        .curve(0.69, 0.74, control: (0.65, 0.66)),
        .curve(0.68, 0.98, control: (0.70, 0.86)),
        .move(0.525, 0.98),
        .line(0.50, 0.77)
    ]

    private static let sideFront: [Segment] = [
        .move(0.545, 0.225),
        .line(0.555, 0.27),
        .curve(0.64, 0.33, control: (0.62, 0.28)),
        .curve(0.645, 0.41, control: (0.665, 0.37)),
        .curve(0.615, 0.50, control: (0.63, 0.45)),
        .line(0.62, 0.60),
        .curve(0.635, 0.72, control: (0.615, 0.66)),
        .curve(0.625, 0.98, control: (0.65, 0.85))
    ]

    private static let sideBack: [Segment] = [
        .move(0.455, 0.215),
        .curve(0.43, 0.27, control: (0.45, 0.25)),
        .curve(0.37, 0.35, control: (0.38, 0.28)),
        .curve(0.385, 0.46, control: (0.36, 0.41)),
        .curve(0.415, 0.58, control: (0.41, 0.52)),
        .curve(0.36, 0.71, control: (0.35, 0.63)),
        .curve(0.385, 0.79, control: (0.355, 0.77)),
        .curve(0.41, 0.98, control: (0.395, 0.88))
    ]

    func path(in rect: CGRect) -> Path {
        var path = Path()

        func point(_ x: CGFloat, _ y: CGFloat, mirrored: Bool) -> CGPoint {
            CGPoint(x: rect.minX + (mirrored ? 1 - x : x) * rect.width, y: rect.minY + y * rect.height)
        }

        func add(_ segments: [Segment], mirrored: Bool = false) {
            for segment in segments {
                switch segment {
                case let .move(x, y):
                    path.move(to: point(x, y, mirrored: mirrored))
                case let .line(x, y):
                    path.addLine(to: point(x, y, mirrored: mirrored))
                case let .curve(x, y, control):
                    path.addQuadCurve(to: point(x, y, mirrored: mirrored), control: point(control.0, control.1, mirrored: mirrored))
                }
            }
        }

        // Head: ~0.173 of the frame height.
        let headHeight = 0.173 * rect.height
        let headWidth = headHeight * 0.75
        path.addEllipse(in: CGRect(x: rect.midX - headWidth / 2, y: rect.minY + 0.05 * rect.height, width: headWidth, height: headHeight))

        switch pose {
        case .front, .back:
            add(Self.frontHalf)
            add(Self.frontHalf, mirrored: true)
        case .side:
            add(Self.sideFront)
            add(Self.sideBack)
            let armWidth = 0.09 * rect.width
            path.addRoundedRect(
                in: CGRect(x: rect.midX - armWidth / 2, y: rect.minY + 0.30 * rect.height, width: armWidth, height: 0.48 * rect.height),
                cornerSize: CGSize(width: armWidth / 2, height: armWidth / 2)
            )
        }
        return path
    }
}

// MARK: - Capture screen

struct GuidedCaptureView: View {
    let pose: ScanPose
    @ObservedObject var camera: CameraController
    let onUsePhoto: (UIImage) -> Void

    @State private var captured: UIImage?
    @State private var timerSeconds = 10
    @State private var countdown: Int?
    @State private var countdownTask: Task<Void, Never>?
    @State private var libraryItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("\(pose.title.uppercased()) · \(pose.rawValue + 1) OF \(ScanPose.allCases.count)")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(Theme.accent)
                Text(captured == nil ? pose.instruction : "Check the photo: whole body inside the frame, relaxed pose, good lighting.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            Color.black
                .aspectRatio(3.0 / 4.0, contentMode: .fit)
                .overlay { viewfinder }
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 16)

            controls
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
        }
        .onChange(of: libraryItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    captured = image
                }
                libraryItem = nil
            }
        }
        .onDisappear { cancelCountdown() }
    }

    @ViewBuilder
    private var viewfinder: some View {
        if let captured {
            Image(uiImage: captured)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                switch camera.state {
                case .ready:
                    CameraPreview(session: camera.session)
                    PoseOutline(pose: pose)
                        .stroke(Theme.accent.opacity(0.9), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round, dash: [9, 7]))
                        // The front camera preview is mirrored, so flip the side profile to match.
                        .scaleEffect(x: pose == .side && camera.position == .front ? -1 : 1, y: 1)
                        .shadow(color: .black.opacity(0.5), radius: 2)
                    VStack {
                        Spacer()
                        Text("Line your body up with the outline")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.45))
                            .clipShape(Capsule())
                            .padding(.bottom, 10)
                    }
                case .idle, .loading:
                    ProgressView().tint(Theme.accent)
                case .denied:
                    unavailableMessage(
                        title: "Camera access is off",
                        detail: "Allow camera access in Settings to take a guided scan.",
                        showSettings: true
                    )
                case .unavailable:
                    unavailableMessage(
                        title: "No camera available",
                        detail: "This device has no camera. You can pick a photo instead.",
                        showSettings: false
                    )
                }

                if let countdown {
                    Text("\(countdown)")
                        .font(.system(size: 120, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 8)
                        .contentTransition(.numericText())
                }
            }
        }
    }

    private func unavailableMessage(title: String, detail: String, showSettings: Bool) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 36))
                .foregroundColor(Theme.taupeGrey)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Text(detail)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if showSettings {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.accent)
            }
            PhotosPicker(selection: $libraryItem, matching: .images) {
                Text("Choose from Library")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.accent)
            }
        }
        .padding(24)
    }

    @ViewBuilder
    private var controls: some View {
        if let captured {
            HStack(spacing: 12) {
                Button {
                    self.captured = nil
                } label: {
                    Text("Retake").pumpButtonStyle(isPrimary: false)
                }
                Button {
                    onUsePhoto(captured)
                    self.captured = nil
                } label: {
                    Text("Use Photo").pumpButtonStyle()
                }
            }
        } else {
            HStack {
                HStack(spacing: 6) {
                    ForEach([0, 5, 10], id: \.self) { seconds in
                        Button {
                            timerSeconds = seconds
                        } label: {
                            Text(seconds == 0 ? "Off" : "\(seconds)s")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(timerSeconds == seconds ? Theme.pitchBlack : Theme.textSecondary)
                                .frame(width: 38, height: 30)
                                .background(timerSeconds == seconds ? Theme.accent : Theme.cardBackground)
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: shutterTapped) {
                    ZStack {
                        Circle()
                            .stroke(Theme.textPrimary, lineWidth: 4)
                            .frame(width: 74, height: 74)
                        if countdown == nil {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 60, height: 60)
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                                .frame(width: 28, height: 28)
                        }
                    }
                }
                .disabled(camera.state != .ready)
                .opacity(camera.state == .ready ? 1 : 0.4)

                Button {
                    camera.flip()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Theme.textPrimary)
                        .frame(width: 48, height: 48)
                        .background(Theme.cardBackground)
                        .clipShape(Circle())
                }
                .disabled(camera.state != .ready || countdown != nil)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func shutterTapped() {
        if countdown != nil {
            cancelCountdown()
            return
        }
        countdownTask = Task { @MainActor in
            var remaining = timerSeconds
            while remaining > 0 {
                withAnimation { countdown = remaining }
                AudioServicesPlaySystemSound(1103)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                remaining -= 1
            }
            countdown = nil
            camera.capture { image in
                if let image { captured = image }
            }
        }
    }

    private func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
        countdown = nil
    }
}
