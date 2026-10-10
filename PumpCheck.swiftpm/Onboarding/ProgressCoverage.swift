import SwiftUI

/// Which part of the 9:16 progress frame each aligned photo actually covers, so a set of photos can be
/// shown with one shared crop that hides the black borders left by zoomed-out or rotated photos.
///
/// A coverage is the photo's four corners in normalized frame coordinates (0...1), stored as
/// [x0, y0, x1, y1, x2, y2, x3, y3] in order around the edge. nil means it covers the whole frame.
enum ProgressCoverage {
    /// Where the shared crop is centered when the photos allow it: the eye line, so the eyes stay where they were aligned.
    static let anchor = UnitPoint(x: 0.5, y: EyeGuide.eyeY)

    /// Corners of a photo placed with the crop editor's offset (frame points), scale and rotation.
    /// Mirrors how the editor draws it: scaled to fill the frame, then offset, scaled and rotated about the center.
    static func coverage(imageSize: CGSize, frameSize: CGSize, scale: CGFloat, offset: CGSize, rotation: Angle) -> [Double] {
        guard imageSize.width > 0, imageSize.height > 0, frameSize.width > 0, frameSize.height > 0 else { return [] }
        let fill = max(frameSize.width / imageSize.width, frameSize.height / imageSize.height)
        let hw = imageSize.width * fill / 2, hh = imageSize.height * fill / 2
        let c = CGFloat(cos(rotation.radians)), s = CGFloat(sin(rotation.radians))

        var result: [Double] = []
        for (x, y) in [(-hw, -hh), (hw, -hh), (hw, hh), (-hw, hh)] {
            let px = (x + offset.width) * scale, py = (y + offset.height) * scale
            let rx = px * c - py * s, ry = px * s + py * c
            result.append(Double((rx + frameSize.width / 2) / frameSize.width))
            result.append(Double((ry + frameSize.height / 2) / frameSize.height))
        }
        return result
    }

    /// The largest 9:16 crop that every photo covers, as close as possible to centering on the eye line.
    /// Every photo gets the same crop, so they stay aligned with each other.
    @MainActor static func commonCrop(_ coverages: [[Double]?]) -> ProgressCrop {
        let quads = coverages.compactMap { $0 }.filter { $0.count == 8 }
        guard !quads.isEmpty else { return .full }
        // Views call this on every redraw (e.g. while dragging the slider), so reuse the last answer
        if let cached = lastCrop, cached.quads == quads { return cached.crop }
        let crop = computeCrop(quads)
        lastCrop = (quads, crop)
        return crop
    }

    @MainActor private static var lastCrop: (quads: [[Double]], crop: ProgressCrop)?

    private static func computeCrop(_ quads: [[Double]]) -> ProgressCrop {

        func covered(_ origin: CGPoint, _ k: CGFloat) -> Bool {
            let corners = [(origin.x, origin.y), (origin.x + k, origin.y),
                           (origin.x + k, origin.y + k), (origin.x, origin.y + k)]
            return quads.allSatisfy { quad in corners.allSatisfy { contains(quad, $0) } }
        }

        /// The covered crop of size `k` (fraction of the frame) closest to the eye-centered position.
        func bestOrigin(_ k: CGFloat) -> CGPoint? {
            let preferred = CGPoint(x: anchor.x * (1 - k), y: anchor.y * (1 - k))
            if covered(preferred, k) { return preferred }
            let steps = 40
            var best: CGPoint?
            var bestDistance = CGFloat.infinity
            for i in 0...steps {
                for j in 0...steps {
                    let origin = CGPoint(x: (1 - k) * CGFloat(i) / CGFloat(steps), y: (1 - k) * CGFloat(j) / CGFloat(steps))
                    let distance = hypot(origin.x - preferred.x, origin.y - preferred.y)
                    if distance < bestDistance, covered(origin, k) {
                        best = origin
                        bestDistance = distance
                    }
                }
            }
            return best
        }

        if covered(.zero, 1) { return .full }
        var low: CGFloat = 0.25, high: CGFloat = 1
        guard var origin = bestOrigin(low) else { return .full } // Photos barely overlap; leave them uncropped
        for _ in 0..<16 {
            let mid = (low + high) / 2
            if let found = bestOrigin(mid) {
                low = mid
                origin = found
            } else {
                high = mid
            }
        }
        // Scaling by 1/k about this point maps the crop's origin to the frame's origin
        return ProgressCrop(scale: low, anchor: UnitPoint(x: origin.x / (1 - low), y: origin.y / (1 - low)))
    }

    /// The part of a saved progress photo the original photo covers (its bounding box within the frame),
    /// without the black border left by zooming out. Returns the image unchanged when there's nothing to trim.
    static func trimmed(_ image: UIImage, coverage: [Double]?) -> UIImage {
        guard let coverage, coverage.count == 8, let cgImage = image.cgImage else { return image }
        let xs = stride(from: 0, to: 8, by: 2).map { min(max(coverage[$0], 0), 1) }
        let ys = stride(from: 1, to: 8, by: 2).map { min(max(coverage[$0], 0), 1) }
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max(),
              maxX > minX, maxY > minY, (maxX - minX) * (maxY - minY) < 0.999 else { return image }

        let width = Double(cgImage.width), height = Double(cgImage.height)
        let rect = CGRect(x: minX * width, y: minY * height, width: (maxX - minX) * width, height: (maxY - minY) * height).integral
        guard let cropped = cgImage.cropping(to: rect) else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    /// A saved progress photo cut to a shared crop, e.g. for posting a set of photos that line up without black borders.
    static func cropped(_ image: UIImage, to crop: ProgressCrop) -> UIImage {
        guard crop.scale < 1, let cgImage = image.cgImage else { return image }
        let width = Double(cgImage.width), height = Double(cgImage.height)
        let k = Double(crop.scale)
        // Zooming by 1/k about the anchor shows the region starting at anchor * (1 - k)
        let rect = CGRect(x: Double(crop.anchor.x) * (1 - k) * width, y: Double(crop.anchor.y) * (1 - k) * height,
                          width: k * width, height: k * height).integral
        guard let result = cgImage.cropping(to: rect) else { return image }
        return UIImage(cgImage: result, scale: image.scale, orientation: image.imageOrientation)
    }

    /// Whether `point` is inside the convex quad (same side of all four edges).
    private static func contains(_ quad: [Double], _ point: (CGFloat, CGFloat)) -> Bool {
        var sign: Double = 0
        for i in 0..<4 {
            let ax = quad[i * 2], ay = quad[i * 2 + 1]
            let bx = quad[(i + 1) % 4 * 2], by = quad[(i + 1) % 4 * 2 + 1]
            let cross = (bx - ax) * (Double(point.1) - ay) - (by - ay) * (Double(point.0) - ax)
            if abs(cross) < 1e-9 { continue }
            if sign == 0 { sign = cross } else if (cross > 0) != (sign > 0) { return false }
        }
        return true
    }
}

/// A shared crop: a `scale` fraction of the frame, shown by zooming 1/scale about `anchor`.
struct ProgressCrop {
    var scale: CGFloat
    var anchor: UnitPoint

    static let full = ProgressCrop(scale: 1, anchor: .center)
}
