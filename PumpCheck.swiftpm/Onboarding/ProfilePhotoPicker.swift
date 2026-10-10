import SwiftUI

/// Picks a new profile picture, limited to photos already in the progress diary.
struct ProfilePhotoPicker: View {
    var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    /// The chosen photo, shown in the crop step before saving
    @State private var croppingImage: UIImage?

    private var entries: [ProgressEntry] {
        viewModel.progressEntries
            .filter { !$0.photoBase64.isEmpty }
            .sorted { $0.date > $1.date }
    }

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        if let croppingImage {
            ProfilePhotoCropView(
                image: croppingImage,
                onCancel: { self.croppingImage = nil },
                onSave: { cropped in
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    viewModel.setProfilePhoto(from: cropped)
                    dismiss()
                }
            )
        } else {
            grid
        }
    }

    private var grid: some View {
        ZStack {
            Theme.pitchBlack.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profile Picture")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                            Text("Choose a photo from your progress diary.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.textSecondary)
                        }
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(Theme.cardBackground)
                                .clipShape(Circle())
                        }
                    }

                    if entries.isEmpty {
                        Text("No progress photos yet. Log one in the Progress tab first.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                            .padding(.top, 24)
                    } else {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(entries) { entry in
                                photoCell(entry)
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
    }

    private func photoCell(_ entry: ProgressEntry) -> some View {
        Button(action: { select(entry) }) {
            Color.clear
                .aspectRatio(9 / 16, contentMode: .fit)
                .overlay {
                    if let image = ImageCache.decode(base64: entry.photoBase64) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Theme.cardBackground
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    Text(entry.date.formatted(.dateTime.day().month(.abbreviated).year(.twoDigits)))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(6)
                        .shadow(color: .black.opacity(0.6), radius: 3)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func select(_ entry: ProgressEntry) {
        guard let image = ImageCache.decode(base64: entry.photoBase64) else { return }
        // Drop the black border some diary photos have, so it can't end up inside the circle
        croppingImage = ProgressCoverage.trimmed(image, coverage: entry.coverage)
    }
}
