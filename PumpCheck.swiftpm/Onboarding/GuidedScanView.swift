import SwiftUI
import PhotosUI

struct GuidedScanView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var camera = CameraController()

    enum Step: Equatable {
        case instructions
        case capture(ScanPose)
        case dream
        case review
        case results
    }

    @State private var step: Step = .instructions
    @State private var photos: [ScanPose: UIImage] = [:]
    @State private var dreamImage: UIImage?
    @State private var dreamItem: PhotosPickerItem?
    @State private var retakeReturnsToReview = false
    @State private var isAnalyzing = false
    @State private var result: GuidedScanResult?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()

                switch step {
                case .instructions:
                    instructionsView
                case .capture(let pose):
                    GuidedCaptureView(pose: pose, camera: camera) { image in
                        photos[pose] = image
                        if retakeReturnsToReview {
                            retakeReturnsToReview = false
                            step = .review
                        } else if let next = pose.next {
                            step = .capture(next)
                        } else {
                            step = dreamImage == nil ? .dream : .review
                        }
                    }
                case .dream:
                    dreamView
                case .review:
                    reviewView
                case .results:
                    if let result {
                        resultsView(result)
                    }
                }
            }
            .navigationTitle("Guided Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .onChange(of: step) { _, newStep in
            if case .capture = newStep {
                camera.start()
            } else {
                camera.stop()
            }
        }
        .onChange(of: dreamItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    dreamImage = image
                    errorMessage = nil
                }
            }
        }
        .onDisappear { camera.stop() }
    }

    // MARK: - Instructions

    private var instructionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Get the most accurate score")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text("You'll take 3 photos (front, side, back), then pick your dream physique. Scanning the same way every time is what makes your score comparable between scans.")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textSecondary)
                }

                VStack(spacing: 12) {
                    instructionRow(icon: "iphone", title: "Prop your phone up",
                                   detail: "Upright at chest height, about 2 m (6-7 ft) away. Use the timer so you have time to get into position.")
                    instructionRow(icon: "sun.max.fill", title: "Face the light",
                                   detail: "Stand facing a window or a bright light. Avoid light from behind you or only from directly overhead.")
                    instructionRow(icon: "tshirt.fill", title: "Show your physique",
                                   detail: "Shirtless or a sports bra, with shorts that show your upper thighs.")
                    instructionRow(icon: "square.dashed", title: "Plain background",
                                   detail: "A plain wall works best. Keep other people and clutter out of the frame.")
                    instructionRow(icon: "figure.stand", title: "Relaxed, natural pose",
                                   detail: "Stand tall and breathe normally. Don't flex, pump up or suck in your stomach. Line your body up with the outline.")
                    instructionRow(icon: "clock.fill", title: "Same conditions each time",
                                   detail: "Ideally in the morning before eating, and never right after a workout.")
                }

                Button {
                    retakeReturnsToReview = false
                    step = .capture(.front)
                } label: {
                    Text("Start Scan").pumpButtonStyle()
                }
                .padding(.top, 8)
            }
            .padding(24)
            .padding(.bottom, 40)
        }
    }

    private func instructionRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Theme.accent)
                .frame(width: 36, height: 36)
                .background(Theme.pitchBlack)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Theme.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - Dream physique

    private var dreamView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pick your dream physique")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text("This is your 10/10. The AI scores how close you are to it.")
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textSecondary)
                }

                PhotosPicker(selection: $dreamItem, matching: .images) {
                    Theme.cardBackground
                        .aspectRatio(3.0 / 4.0, contentMode: .fit)
                        .overlay {
                            if let dreamImage {
                                Image(uiImage: dreamImage)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(Theme.taupeGrey)
                                    Text("Select Photo")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Theme.taupeGrey)
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 40)

                VStack(alignment: .leading, spacing: 10) {
                    tipRow("Front-facing, with the upper body clearly visible")
                    tipRow("Good lighting and a sharp, not-too-small photo")
                    tipRow("Relaxed or lightly flexed beats a heavy stage pose")
                    tipRow("Avoid heavily edited or filtered photos")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cardBackground)
                .cornerRadius(14)

                Button {
                    step = .review
                } label: {
                    Text("Continue").pumpButtonStyle()
                }
                .disabled(dreamImage == nil)
                .opacity(dreamImage == nil ? 0.5 : 1)
            }
            .padding(24)
            .padding(.bottom, 40)
        }
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(Theme.accent)
                .padding(.top, 3)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
        }
    }

    // MARK: - Review

    private var reviewView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Tap a photo to retake it")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(ScanPose.allCases, id: \.self) { pose in
                        Button {
                            retakeReturnsToReview = true
                            step = .capture(pose)
                        } label: {
                            thumbnail(photos[pose], label: pose.title)
                        }
                        .disabled(isAnalyzing)
                    }
                    PhotosPicker(selection: $dreamItem, matching: .images) {
                        thumbnail(dreamImage, label: "Dream")
                    }
                    .disabled(isAnalyzing)
                }

                if let errorMessage {
                    VStack(spacing: 8) {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .textSelection(.enabled)
                        Button {
                            UIPasteboard.general.string = errorMessage
                        } label: {
                            Text("Copy Error")
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Theme.cardBackground)
                                .cornerRadius(8)
                        }
                    }
                }

                Button(action: analyze) {
                    HStack {
                        if isAnalyzing {
                            ProgressView().tint(Theme.pitchBlack)
                        }
                        Text(isAnalyzing ? "Analyzing..." : "Analyze My Physique")
                    }
                    .pumpButtonStyle()
                }
                .disabled(isAnalyzing || !hasAllPhotos)

                if isAnalyzing {
                    Text("This can take up to a minute.")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(24)
            .padding(.bottom, 40)
        }
    }

    private func thumbnail(_ image: UIImage?, label: String) -> some View {
        Theme.cardBackground
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 28))
                        .foregroundColor(Theme.taupeGrey)
                }
            }
            .overlay(alignment: .bottomLeading) {
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.55))
                    .clipShape(Capsule())
                    .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var hasAllPhotos: Bool {
        ScanPose.allCases.allSatisfy { photos[$0] != nil } && dreamImage != nil
    }

    // MARK: - Results

    private func resultsView(_ res: GuidedScanResult) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", res.matchScore))
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundColor(Theme.accent)
                        Text("/ 10")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.taupeGrey)
                    }
                    Text("MATCH TO DREAM PHYSIQUE")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.taupeGrey)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.cardBackground)
                            Capsule()
                                .fill(Theme.accent)
                                .frame(width: geo.size.width * res.matchScore / 10)
                        }
                    }
                    .frame(height: 10)
                    .padding(.top, 4)

                    Text("\(res.confidence.capitalized) confidence · \(res.confidenceReason)")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }

                if res.photoQuality != "good" && !res.photoQualityNotes.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Theme.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(res.photoQuality == "poor" ? "Photos made this hard to score" : "Tip for a more accurate scan")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            Text(res.photoQualityNotes)
                                .font(.system(size: 13))
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.accent.opacity(0.5), lineWidth: 1))
                }

                if !res.summary.isEmpty {
                    Text(res.summary)
                        .font(.system(size: 15))
                        .foregroundColor(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                }

                textCard(title: "How the AI read your goal", text: res.dreamPhysiqueRead)
                textCard(title: "How the AI read you", text: res.currentPhysiqueRead)

                if !res.proportions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Proportions")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                        HStack {
                            Text("").frame(maxWidth: .infinity, alignment: .leading)
                            Text("YOU").frame(width: 80)
                            Text("GOAL").frame(width: 80)
                        }
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(Theme.taupeGrey)
                        ForEach(res.proportions, id: \.self) { row in
                            HStack {
                                Text(row.metric)
                                    .font(.system(size: 14))
                                    .foregroundColor(Theme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(row.current)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.textPrimary)
                                    .frame(width: 80)
                                Text(row.goal)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.accent)
                                    .frame(width: 80)
                            }
                            .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Theme.cardBackground)
                    .cornerRadius(12)
                }

                bulletCard(title: "What's Similar", items: res.similarities)
                bulletCard(title: "What Needs to Improve", items: res.areasToImprove)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Action Plan: Exercises to Get There")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    ForEach(Array(res.recommendedExercises.enumerated()), id: \.offset) { index, exercise in
                        HStack(spacing: 16) {
                            Text("\(index + 1)")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(Theme.pitchBlack)
                                .frame(width: 32, height: 32)
                                .background(Theme.accent)
                                .clipShape(Circle())
                            Text(exercise)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                            Spacer()
                        }
                        .padding(16)
                        .background(Theme.cardBackground)
                        .cornerRadius(12)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    photos = [:]
                    result = nil
                    errorMessage = nil
                    step = .instructions
                } label: {
                    Text("Scan Again").pumpButtonStyle(isPrimary: false)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .padding(.bottom, 40)
        }
    }

    private func textCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
    }

    private func bulletCard(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Theme.accent)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Analysis

    private var userStats: String {
        func value(_ text: String, unit: String) -> String {
            text.isEmpty ? "Unknown" : "\(text) \(unit)".trimmingCharacters(in: .whitespaces)
        }
        let years = Int(viewModel.yearsLifted) ?? 0
        let months = Int(viewModel.monthsLifted) ?? 0
        let experience = (years == 0 && months == 0) ? "Unknown" : "\(years) years, \(months) months"
        return """
        Height: \(value(viewModel.height, unit: viewModel.isHeightCm ? "cm" : ""))
        Weight: \(value(viewModel.weight, unit: viewModel.isWeightKg ? "kg" : "lbs"))
        Age: \(viewModel.age.isEmpty ? "Unknown" : viewModel.age)
        Training experience: \(experience)
        Natural (no PEDs): \(viewModel.isNatty ? "Yes" : "No")
        """
    }

    private func analyze() {
        guard let front = photos[.front], let side = photos[.side], let back = photos[.back], let dream = dreamImage else { return }
        isAnalyzing = true
        errorMessage = nil
        let stats = userStats

        Task {
            do {
                let res = try await GuidedScanService.shared.analyze(front: front, side: side, back: back, dream: dream, userStats: stats)
                await MainActor.run {
                    result = res
                    isAnalyzing = false
                    step = .results
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                }
            }
        }
    }
}
