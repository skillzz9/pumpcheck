import SwiftUI
import PhotosUI

struct TestComparisonView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.dismiss) var dismiss
    @State private var currentItem: PhotosPickerItem? = nil
    @State private var dreamItem: PhotosPickerItem? = nil
    @State private var currentImageData: Data? = nil
    @State private var dreamImageData: Data? = nil
    @State private var isAnalyzing = false
    @State private var result: ComparisonResult? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        HStack(spacing: 16) {
                            photoSlot(title: "My Physique", item: $currentItem, imageData: currentImageData)
                            photoSlot(title: "Dream Physique", item: $dreamItem, imageData: dreamImageData)
                        }
                        .padding(.horizontal, 24)
                        .onChange(of: currentItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    currentImageData = data
                                    result = nil
                                    errorMessage = nil
                                }
                            }
                        }
                        .onChange(of: dreamItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    dreamImageData = data
                                    result = nil
                                    errorMessage = nil
                                }
                            }
                        }

                        if let currentImageData, let dreamImageData {
                            Button(action: {
                                compare(current: currentImageData, dream: dreamImageData)
                            }) {
                                HStack {
                                    if isAnalyzing {
                                        ProgressView().tint(Theme.pitchBlack)
                                    }
                                    Text(isAnalyzing ? "Comparing..." : "Compare Physiques")
                                }
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.pitchBlack)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.accent)
                                .cornerRadius(16)
                            }
                            .disabled(isAnalyzing)
                            .padding(.horizontal, 24)
                        }

                        if let error = errorMessage {
                            VStack(spacing: 8) {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                                    .textSelection(.enabled)

                                Button(action: {
                                    UIPasteboard.general.string = error
                                }) {
                                    Text("Copy Error")
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Theme.cardBackground)
                                        .cornerRadius(8)
                                }
                            }
                            .padding()
                        }

                        if let res = result {
                            VStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    Text("\(Int(res.matchPercent.rounded()))%")
                                        .font(.system(size: 48, weight: .black, design: .rounded))
                                        .foregroundColor(Theme.accent)
                                    Text("MATCH TO DREAM PHYSIQUE")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Theme.taupeGrey)

                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Theme.cardBackground)
                                            Capsule()
                                                .fill(Theme.accent)
                                                .frame(width: geo.size.width * res.matchPercent / 100)
                                        }
                                    }
                                    .frame(height: 10)
                                    .padding(.top, 4)

                                    if !res.summary.isEmpty {
                                        Text(res.summary)
                                            .font(.system(size: 14))
                                            .foregroundColor(Theme.textSecondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.top, 8)
                                    }
                                }
                                .padding(.bottom, 8)

                                bulletCard(title: "What's Similar", items: res.similarities)
                                bulletCard(title: "What Needs to Improve", items: res.areasToImprove)

                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Action Plan: Exercises to Get There")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)

                                    ForEach(Array(res.recommendedExercises.enumerated()), id: \.offset) { index, exercise in
                                        HStack(alignment: .center, spacing: 16) {
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
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Theme.taupeGrey.opacity(0.2), lineWidth: 1)
                                        )
                                        .shadow(color: Theme.accent.opacity(0.1), radius: 5, x: 0, y: 2)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        }
                    }
                    .padding(.top, 24)
                }
            }
            .navigationTitle("AI Comparison Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }

    private func photoSlot(title: String, item: Binding<PhotosPickerItem?>, imageData: Data?) -> some View {
        VStack(spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Theme.taupeGrey)

            PhotosPicker(selection: item, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.cardBackground)

                    if let imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        VStack {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Theme.taupeGrey)
                            Text("Select Photo")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Theme.taupeGrey)
                                .padding(.top, 6)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Theme.accent.opacity(imageData == nil ? 0 : 0.3), radius: 10, x: 0, y: 5)
            }
        }
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

    private func compare(current: Data, dream: Data) {
        guard let currentImage = UIImage(data: current),
              let currentCompressed = currentImage.jpegData(compressionQuality: 0.2),
              let dreamImage = UIImage(data: dream),
              let dreamCompressed = dreamImage.jpegData(compressionQuality: 0.2) else { return }

        isAnalyzing = true
        errorMessage = nil
        result = nil

        Task {
            do {
                let res = try await PhysiqueScoringService.shared.comparePhysiques(
                    currentImageBase64: currentCompressed.base64EncodedString(),
                    dreamImageBase64: dreamCompressed.base64EncodedString(),
                    height: viewModel.height,
                    weight: viewModel.weight
                )
                await MainActor.run {
                    self.result = res
                    self.isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isAnalyzing = false
                }
            }
        }
    }
}
