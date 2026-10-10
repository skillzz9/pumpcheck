import SwiftUI

/// How progress photo sliders move between photos. Persisted globally so every slider shares it.
enum ProgressSliderMode: String {
    case flicker // Snap from one photo to the next
    case fade    // Cross-fade: older photo fades out over the newer one

    static let storageKey = "progressSliderMode"
}

/// Renders the photo(s) for a progress slider position.
/// In fade mode, the older photo sits on top with decreasing opacity and the newer photo shows through underneath.
struct ProgressPhotoStack: View {
    let photos: [String] // Array of base64 strings
    let sliderValue: Double
    let mode: ProgressSliderMode
    var fill: Bool = false // true = square-cropped (feed), false = fit (profile / progress)
    var crop: ProgressCrop = .full // Fit mode: shared crop that hides black borders, see ProgressCoverage

    static let maxFitHeight: CGFloat = 480

    var body: some View {
        let maxIndex = max(photos.count - 1, 0)
        let clamped = min(max(sliderValue, 0), Double(maxIndex))

        if mode == .fade {
            let lower = Int(clamped.rounded(.down))
            let upper = min(lower + 1, maxIndex)
            let t = clamped - Double(lower)

            ZStack {
                photoLayer(upper)
                photoLayer(lower)
                    .opacity(1 - t)
            }
        } else {
            photoLayer(Int(clamped.rounded()))
        }
    }

    @ViewBuilder
    private func photoLayer(_ index: Int) -> some View {
        if index >= 0 && index < photos.count,
           let uiImage = ImageCache.decode(base64: photos[index]) {
            if fill {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.0, contentMode: .fit)
                    .clipped()
            } else {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: Self.maxFitHeight) // Keep the whole photo plus slider on screen
                    .scaleEffect(1 / crop.scale, anchor: crop.anchor)
                    .clipped()
                    .frame(maxWidth: .infinity)
                    .background(Theme.pitchBlack)
            }
        } else {
            Rectangle()
                .fill(Theme.cardBackground)
                .aspectRatio(fill ? 1.0 : 9.0 / 16.0, contentMode: .fit)
                .frame(maxHeight: fill ? nil : Self.maxFitHeight)
                .frame(maxWidth: .infinity)
        }
    }
}

/// Small pill that toggles between flicker and fade mode.
struct ProgressSliderModeToggle: View {
    @Binding var mode: ProgressSliderMode

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = (mode == .fade) ? .flicker : .fade
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: mode == .fade ? "square.on.square" : "rectangle.stack")
                Text(mode == .fade ? "Fade" : "Flicker")
            }
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .environment(\.colorScheme, .dark)
        }
        .buttonStyle(.plain)
        .padding(10)
    }
}
