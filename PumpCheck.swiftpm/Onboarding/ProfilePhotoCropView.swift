import SwiftUI

/// Positions a photo inside the profile circle (drag to move, pinch to zoom) and returns the square crop.
struct ProfilePhotoCropView: View {
    let image: UIImage
    let onCancel: () -> Void
    let onSave: (UIImage) -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let maxScale: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            let cropSize = min(geo.size.width - 48, 340)
            let displayed = displayedSize(cropSize: cropSize)

            VStack(spacing: 24) {
                HStack {
                    Button("Cancel", action: onCancel)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("Move and Scale")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Button("Save") { onSave(renderCrop(cropSize: cropSize)) }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.accent)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Photo area: everything outside the circle is dimmed, and nothing spills past it
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: displayed.width, height: displayed.height)
                        .offset(offset)

                    Rectangle()
                        .fill(Theme.pitchBlack.opacity(0.75))
                        .overlay(
                            Circle()
                                .frame(width: cropSize, height: cropSize)
                                .blendMode(.destinationOut)
                        )
                        .compositingGroup()
                        .allowsHitTesting(false)

                    Circle()
                        .stroke(Theme.paleSky.opacity(0.8), lineWidth: 2)
                        .frame(width: cropSize, height: cropSize)
                        .allowsHitTesting(false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .contentShape(Rectangle())
                .gesture(
                    SimultaneousGesture(
                        DragGesture()
                            .onChanged { value in
                                offset = clamped(
                                    CGSize(width: lastOffset.width + value.translation.width,
                                           height: lastOffset.height + value.translation.height),
                                    cropSize: cropSize
                                )
                            }
                            .onEnded { _ in lastOffset = offset },
                        MagnificationGesture()
                            .onChanged { value in
                                scale = min(max(lastScale * value, 1), maxScale)
                                offset = clamped(offset, cropSize: cropSize)
                            }
                            .onEnded { _ in
                                lastScale = scale
                                lastOffset = offset
                            }
                    )
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.3)) {
                        scale = 1; lastScale = 1
                        offset = .zero; lastOffset = .zero
                    }
                }

                Text("Drag to move · Pinch to zoom")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.bottom, 24)
            }
        }
        .background(Theme.pitchBlack.ignoresSafeArea())
    }

    /// Image size on screen: fills the circle at 1×, larger when zoomed.
    private func displayedSize(cropSize: CGFloat) -> CGSize {
        let fill = cropSize / min(image.size.width, image.size.height)
        return CGSize(width: image.size.width * fill * scale, height: image.size.height * fill * scale)
    }

    /// Keeps the image covering the whole circle, so no empty space shows inside it.
    private func clamped(_ proposed: CGSize, cropSize: CGFloat) -> CGSize {
        let displayed = displayedSize(cropSize: cropSize)
        let maxX = max((displayed.width - cropSize) / 2, 0)
        let maxY = max((displayed.height - cropSize) / 2, 0)
        return CGSize(width: min(max(proposed.width, -maxX), maxX),
                      height: min(max(proposed.height, -maxY), maxY))
    }

    /// Renders the square under the circle; the profile shows it clipped to a circle.
    private func renderCrop(cropSize: CGFloat) -> UIImage {
        let displayed = displayedSize(cropSize: cropSize)
        let outputSide: CGFloat = 600
        let factor = outputSide / cropSize
        // Where the image's top-left sits relative to the crop square's top-left, in screen points
        let originX = (cropSize - displayed.width) / 2 + offset.width
        let originY = (cropSize - displayed.height) / 2 + offset.height

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: outputSide, height: outputSide), format: format).image { _ in
            image.draw(in: CGRect(x: originX * factor, y: originY * factor,
                                  width: displayed.width * factor, height: displayed.height * factor))
        }
    }
}
