import SwiftUI
import PhotosUI

/// Debug screen: scans one meal photo on Opus 5 and Sonnet 5 side by side to compare accuracy and cost.
struct TestMealModelsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var photo: UIImage? = nil
    @State private var isRunning = false
    @State private var runs: [ModelRun] = []

    private static let models: [ScanModel] = [.opus5, .sonnet5]

    struct ModelRun: Identifiable {
        let model: ScanModel
        var id: String { model.rawValue }
        var seconds: Double = 0
        var usage = ScanUsage()
        var name = ""
        var components: [EditableComponent] = []
        var error: String? = nil

        var totalCalories: Int { components.reduce(0) { $0 + $1.calories } }
        var totalProtein: Int { components.reduce(0) { $0 + $1.protein } }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            if let photo {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 260)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 36))
                                    Text("Select Meal Photo")
                                        .font(.headline)
                                }
                                .foregroundColor(Theme.taupeGrey)
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    photo = UIImage(data: data)
                                    runs = []
                                }
                            }
                        }

                        Button(action: runComparison) {
                            HStack(spacing: 8) {
                                if isRunning { ProgressView().tint(Theme.pitchBlack) }
                                Text(isRunning ? "Scanning on both models…" : "Compare Opus 5 vs Sonnet 5")
                            }
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.pitchBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.accent)
                            .cornerRadius(16)
                        }
                        .disabled(photo == nil || isRunning)
                        .opacity(photo == nil ? 0.5 : 1)

                        ForEach(runs) { run in
                            runCard(run)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Meal Model Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func runCard(_ run: ModelRun) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(run.model.displayName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Text(String(format: "%.1fs", run.seconds))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }
            .foregroundColor(Theme.textPrimary)

            if let error = run.error {
                Text(error)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.red)
            } else {
                Text(run.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                ForEach(Array(run.components.enumerated()), id: \.offset) { _, component in
                    HStack {
                        Text(component.name)
                        Spacer()
                        Text("\(Int(component.grams))g · \(component.calories) kcal")
                            .foregroundColor(Theme.textSecondary)
                    }
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                }

                Divider()

                HStack {
                    Text("Total: \(run.totalCalories) kcal · \(run.totalProtein)g protein")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Spacer()
                }
                .foregroundColor(Theme.textPrimary)
            }

            Text(String(format: "Cost: %.2f¢  (%d in / %d out tokens)",
                        run.usage.cost(on: run.model) * 100, run.usage.inputTokens, run.usage.outputTokens))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(16)
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent.opacity(0.4), lineWidth: 1))
    }

    private func runComparison() {
        guard let photo else { return }
        isRunning = true
        runs = []
        Task {
            let results = await withTaskGroup(of: ModelRun.self) { group in
                for model in Self.models {
                    group.addTask { await scan(photo, on: model) }
                }
                var collected: [ModelRun] = []
                for await run in group { collected.append(run) }
                return collected
            }
            runs = Self.models.compactMap { model in results.first { $0.model == model } }
            isRunning = false
        }
    }

    /// Runs the real scan pipeline (photo analysis, then USDA matching) on one model.
    private func scan(_ photo: UIImage, on model: ScanModel) async -> ModelRun {
        var run = ModelRun(model: model)
        let start = Date()
        do {
            let (result, usage) = try await MealScanService.shared.analyze(photo: photo, description: "", model: model)
            let usda = await MealScanService.shared.matchUSDA(result.components)
            run.usage = usage
            run.name = result.name
            run.components = zip(result.components, usda).map { EditableComponent($0, usda: $1) }
        } catch {
            run.error = error.localizedDescription
        }
        run.seconds = Date().timeIntervalSince(start)
        return run
    }
}
