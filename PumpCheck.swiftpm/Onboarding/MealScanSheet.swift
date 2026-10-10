import SwiftUI
import UIKit

struct PendingMealPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
}

/// An ingredient the user can resize; macros scale with the quantity.
struct EditableComponent: Identifiable {
    let id = UUID()
    var name: String
    var quantityText: String
    let unit: String
    let usdaQuery: String
    let fromLabel: Bool
    /// The USDA entry the macros come from; nil means the AI's own estimate is used.
    let usdaFood: USDAFood?
    // Per-unit values, from USDA when matched, otherwise from the AI estimate
    private let gramsPerUnit: Double
    private let caloriesPerUnit: Double
    private let proteinPerUnit: Double
    private let carbsPerUnit: Double
    private let fatPerUnit: Double

    init(_ scanned: ScannedComponent, usda: USDAFood?) {
        let quantity = scanned.quantity > 0 ? scanned.quantity : 1
        name = scanned.name
        quantityText = Self.format(quantity)
        unit = scanned.unit.isEmpty ? "g" : scanned.unit
        usdaQuery = scanned.usdaQuery
        fromLabel = scanned.fromLabel
        gramsPerUnit = scanned.grams / quantity

        if let usda, scanned.grams > 0 {
            usdaFood = usda
            let gramsPer100PerUnit = gramsPerUnit / 100
            caloriesPerUnit = usda.calories * gramsPer100PerUnit
            proteinPerUnit = usda.protein * gramsPer100PerUnit
            carbsPerUnit = usda.carbs * gramsPer100PerUnit
            fatPerUnit = usda.fat * gramsPer100PerUnit
        } else {
            usdaFood = nil
            caloriesPerUnit = Double(scanned.calories) / quantity
            proteinPerUnit = Double(scanned.protein) / quantity
            carbsPerUnit = Double(scanned.carbs) / quantity
            fatPerUnit = Double(scanned.fat) / quantity
        }
    }

    var sourceLabel: String {
        if let usdaFood { return "USDA · \(usdaFood.description)" }
        return fromLabel ? "Nutrition label" : "AI estimate"
    }

    var quantity: Double { max(Double(quantityText) ?? 0, 0) }
    var grams: Double { gramsPerUnit * quantity }
    var calories: Int { Int((caloriesPerUnit * quantity).rounded()) }
    var protein: Int { Int((proteinPerUnit * quantity).rounded()) }
    var carbs: Int { Int((carbsPerUnit * quantity).rounded()) }
    var fat: Int { Int((fatPerUnit * quantity).rounded()) }

    /// Weighed units step by 10, counted units (eggs, tbsp) by half.
    var step: Double { ["g", "ml"].contains(unit.lowercased()) ? 10 : 0.5 }

    mutating func adjust(by delta: Double) {
        quantityText = Self.format(max(quantity + delta, 0))
    }

    var asScanned: ScannedComponent {
        ScannedComponent(
            name: name, quantity: quantity, unit: unit, grams: gramsPerUnit * quantity,
            usdaQuery: usdaQuery, fromLabel: fromLabel,
            calories: calories, protein: protein, carbs: carbs, fat: fat
        )
    }

    static func format(_ value: Double) -> String {
        value.rounded() == value ? String(Int(value)) : String(format: "%.1f", value)
    }
}

/// Describe → analyze → review ingredients → add to log.
struct MealScanSheet: View {
    let photo: UIImage
    /// The meal, and whether to also save it as a quick add
    let onAdd: (MealEntry, Bool) -> Void

    private enum Stage { case describe, analyzing, review }

    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage = .describe
    @State private var mealDescription = ""
    @State private var mealName = ""
    @State private var components: [EditableComponent] = []
    @State private var correction = ""
    @State private var isFixing = false
    @State private var errorMessage: String?
    @State private var loadingText = "Analyzing your meal..."
    @State private var saveAsQuickAdd = false

    private var totalCalories: Int { components.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Int { components.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Int { components.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Int { components.reduce(0) { $0 + $1.fat } }

    var body: some View {
        ZStack {
            Theme.pitchBlack.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(height: stage == .review ? 180 : 260)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    switch stage {
                    case .describe: describeView
                    case .analyzing: analyzingView
                    case .review: reviewView
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: - Describe

    private var describeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Describe your meal")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            TextField("(optional) e.g. brown rice, chicken thigh cooked in olive oil", text: $mealDescription, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(PumpTextFieldStyle())

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.accent)
            }

            Button(action: analyze) {
                Text("Analyze Meal").pumpButtonStyle()
            }
            .padding(.top, 4)

            Button(action: { dismiss() }) {
                Text("Cancel").pumpButtonStyle(isPrimary: false)
            }
        }
    }

    private var analyzingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                .scaleEffect(1.3)
            Text(loadingText)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    // MARK: - Review

    private var reviewView: some View {
        VStack(alignment: .leading, spacing: 20) {
            TextField("Meal name", text: $mealName)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .textFieldStyle(PumpTextFieldStyle())

            HStack(spacing: 0) {
                stat("\(totalCalories)", "kcal", Theme.textPrimary)
                stat("\(totalProtein)g", "protein", Theme.accent)
                stat("\(totalCarbs)g", "carbs", Theme.paleSky)
                stat("\(totalFat)g", "fat", Theme.darkCoffee)
            }
            .padding(16)
            .background(Theme.cardBackground)
            .cornerRadius(16)

            Text("Ingredients")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            ForEach($components) { $component in
                componentCard($component)
            }

            fixCard

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.accent)
            }

            Toggle(isOn: $saveAsQuickAdd) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Save as Quick Add")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text("Log this meal again with one tap")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .tint(Theme.accent)
            .padding(14)
            .background(Theme.cardBackground)
            .cornerRadius(16)

            Button(action: addToLog) {
                Text("Add to Log").pumpButtonStyle()
            }
            .disabled(components.isEmpty || isFixing)

            Button(action: { dismiss() }) {
                Text("Cancel").pumpButtonStyle(isPrimary: false)
            }
        }
    }

    private func componentCard(_ component: Binding<EditableComponent>) -> some View {
        let c = component.wrappedValue
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Ingredient", text: component.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Button(action: { components.removeAll { $0.id == c.id } }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Text(c.sourceLabel)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(c.usdaFood == nil ? Theme.textSecondary : Theme.accent)
                .lineLimit(1)

            HStack(spacing: 8) {
                stepButton("minus") { component.wrappedValue.adjust(by: -c.step) }

                TextField("0", text: component.quantityText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .frame(width: 64)
                    .padding(.vertical, 8)
                    .background(Theme.pitchBlack.opacity(0.6))
                    .cornerRadius(10)

                stepButton("plus") { component.wrappedValue.adjust(by: c.step) }

                Text(c.unit)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(c.calories) kcal")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text("P \(c.protein) · C \(c.carbs) · F \(c.fat)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                }
                .monospacedDigit()
            }
        }
        .padding(14)
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Theme.textPrimary)
                .frame(width: 30, height: 30)
                .background(Theme.pitchBlack.opacity(0.6))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var fixCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Something off?")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text("Tell the AI what's wrong and it will recalculate.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textSecondary)

            TextField("e.g. \"the rice was double that\" or \"it's brown rice\"", text: $correction, axis: .vertical)
                .lineLimit(1...3)
                .textFieldStyle(PumpTextFieldStyle())
                .disabled(isFixing)

            Button(action: fixWithAI) {
                Group {
                    if isFixing {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Theme.paleSky))
                    } else {
                        Text("Fix with AI")
                    }
                }
                .pumpButtonStyle(isPrimary: false)
            }
            .disabled(isFixing || correction.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
        .background(Theme.cardBackground.opacity(0.5))
        .cornerRadius(16)
    }

    private func stat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    /// Looks the components up in USDA, then shows them for review.
    private func apply(_ result: MealScanResult) async {
        let usda = await MealScanService.shared.matchUSDA(result.components)
        mealName = result.name
        components = zip(result.components, usda).map { EditableComponent($0, usda: $1) }
    }

    private func analyze() {
        errorMessage = nil
        loadingText = "Analyzing your meal..."
        stage = .analyzing
        Task {
            do {
                let result = try await MealScanService.shared.analyze(photo: photo, description: mealDescription)
                loadingText = "Looking up USDA nutrition data..."
                await apply(result)
                stage = .review
            } catch {
                errorMessage = error.localizedDescription
                stage = .describe
            }
        }
    }

    private func fixWithAI() {
        let note = correction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { return }
        errorMessage = nil
        isFixing = true
        Task {
            do {
                await apply(try await MealScanService.shared.fix(
                    photo: photo,
                    name: mealName,
                    components: components.map(\.asScanned),
                    correction: note
                ))
                correction = ""
            } catch {
                errorMessage = error.localizedDescription
            }
            isFixing = false
        }
    }

    private func addToLog() {
        let name = mealName.trimmingCharacters(in: .whitespaces)
        onAdd(MealEntry(
            name: name.isEmpty ? "Meal" : name,
            time: .now,
            calories: totalCalories,
            protein: totalProtein,
            carbs: totalCarbs,
            fat: totalFat
        ), saveAsQuickAdd)
        dismiss()
    }
}

/// System camera for snapping a meal photo.
struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
