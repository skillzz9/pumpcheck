import Foundation

/// Switches for recording demo videos; off unless turned on from the Mac, so they never ship turned on.
/// One launch: `xcrun simctl launch booted com.pumpcheck.app -demoAutoSlide`
/// Every launch: `xcrun simctl spawn booted defaults write com.pumpcheck.app demoAutoSlide -bool YES`
enum DemoMode {
    static let isAutoSlideOn = ProcessInfo.processInfo.arguments.contains("-demoAutoSlide")
        || UserDefaults.standard.bool(forKey: "demoAutoSlide")

    /// Sweeps a progress slider earliest → latest → earliest, 2 seconds each way, until cancelled.
    /// Does nothing unless demo mode is on.
    @MainActor
    static func autoSlide(photoCount: Int, setValue: (Double) -> Void) async {
        guard isAutoSlideOn, photoCount > 1 else { return }
        let end = Double(photoCount - 1)
        let secondsPerSweep = 2.0
        let steps = Int(secondsPerSweep * 60) // 60 updates a second
        var forward = true
        while !Task.isCancelled {
            // Step the value (rather than animating it) so flicker mode shows every photo on the way
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let eased = t * t * (3 - 2 * t)
                setValue((forward ? eased : 1 - eased) * end)
                try? await Task.sleep(nanoseconds: UInt64(secondsPerSweep * 1_000_000_000) / UInt64(steps))
                if Task.isCancelled { return }
            }
            forward.toggle()
        }
    }
}
