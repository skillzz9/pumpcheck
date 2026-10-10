import SwiftUI

enum BiologicalSex: String, CaseIterable {
    case male, female

    var title: String { rawValue.capitalized }
}

/// Activity levels and multipliers from calculator.net's calorie calculator.
enum ActivityLevel: String, CaseIterable {
    case sedentary, light, moderate, active, veryActive, extraActive

    var title: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .active: return "Active"
        case .veryActive: return "Very Active"
        case .extraActive: return "Extra Active"
        }
    }

    var detail: String {
        switch self {
        case .sedentary: return "Little or no exercise"
        case .light: return "Exercise 1-3 times a week"
        case .moderate: return "Exercise 4-5 times a week"
        case .active: return "Daily exercise, or intense exercise 3-4 times a week"
        case .veryActive: return "Intense exercise 6-7 times a week"
        case .extraActive: return "Very intense exercise daily, or a physical job"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.465
        case .active: return 1.55
        case .veryActive: return 1.725
        case .extraActive: return 1.9
        }
    }
}

enum DietGoal: String, CaseIterable {
    case lose, maintain, gain

    var title: String {
        switch self {
        case .lose: return "Lose"
        case .maintain: return "Maintain"
        case .gain: return "Gain"
        }
    }

    /// Daily calories relative to maintenance: about 0.5 kg/week lost, or a lean bulk.
    var calorieAdjustment: Double {
        switch self {
        case .lose: return -500
        case .maintain: return 0
        case .gain: return 300
        }
    }
}

struct NutritionTargets {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int

    /// Mifflin-St Jeor resting burn × activity multiplier, adjusted for the goal.
    /// Protein is 2 g/kg, fat 25% of calories, and carbs fill the rest.
    static func calculate(age: Int, heightCm: Double, weightKg: Double, sex: BiologicalSex, activity: ActivityLevel, goal: DietGoal) -> NutritionTargets {
        let bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + (sex == .male ? 5 : -161)
        let minimum: Double = sex == .male ? 1500 : 1200
        let calories = max(bmr * activity.multiplier + goal.calorieAdjustment, minimum)

        let protein = 2 * weightKg
        let fat = calories * 0.25 / 9
        let carbs = max((calories - protein * 4 - fat * 9) / 4, 0)

        return NutritionTargets(
            calories: Int(calories.rounded()),
            protein: Int(protein.rounded()),
            carbs: Int(carbs.rounded()),
            fat: Int(fat.rounded())
        )
    }
}

extension OnboardingViewModel {
    var heightInCm: Double? {
        let text = height.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        if isHeightCm { return Double(text) }

        // Imperial heights are typed as 5'11, 5'11", 5 11 or plain inches (71)
        let parts = text.split(whereSeparator: { "'\" ".contains($0) }).compactMap { Double($0) }
        guard let first = parts.first else { return nil }
        if parts.count >= 2 { return (first * 12 + parts[1]) * 2.54 }
        return first <= 8 ? first * 12 * 2.54 : first * 2.54
    }

    var weightInKg: Double? {
        guard let value = Double(weight.replacingOccurrences(of: ",", with: ".")) else { return nil }
        return isWeightKg ? value : value * 0.453592
    }

    /// nil until the stats, sex, activity level and goal are all known.
    var nutritionTargets: NutritionTargets? {
        guard let age = Int(age), age > 0,
              let heightCm = heightInCm, heightCm > 0,
              let weightKg = weightInKg, weightKg > 0,
              let sex = BiologicalSex(rawValue: sex),
              let activity = ActivityLevel(rawValue: activityLevel),
              let goal = DietGoal(rawValue: dietGoal) else { return nil }
        return NutritionTargets.calculate(age: age, heightCm: heightCm, weightKg: weightKg, sex: sex, activity: activity, goal: goal)
    }
}

/// Sex, activity level and goal pickers, shared by onboarding and the Diet tab.
struct NutritionSettingsForm: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            section("Sex") {
                optionRow(BiologicalSex.allCases, selected: viewModel.sex, title: \.title) { viewModel.sex = $0.rawValue }
            }

            section("How much do you exercise?") {
                VStack(spacing: 8) {
                    ForEach(ActivityLevel.allCases, id: \.self) { level in
                        activityCard(level)
                    }
                }
            }

            section("Goal") {
                optionRow(DietGoal.allCases, selected: viewModel.dietGoal, title: \.title) { viewModel.dietGoal = $0.rawValue }
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            content()
        }
    }

    private func optionRow<T: RawRepresentable & Hashable>(_ options: [T], selected: String, title: KeyPath<T, String>, select: @escaping (T) -> Void) -> some View where T.RawValue == String {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSelected = option.rawValue == selected
                Button(action: { select(option) }) {
                    Text(option[keyPath: title])
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? Theme.pitchBlack : Theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? Theme.accent : Theme.cardBackground)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func activityCard(_ level: ActivityLevel) -> some View {
        let isSelected = level.rawValue == viewModel.activityLevel
        return Button(action: { viewModel.activityLevel = level.rawValue }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text(level.detail)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Theme.accent : Theme.textSecondary.opacity(0.5))
            }
            .padding(14)
            .background(Theme.cardBackground)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Theme.accent : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

/// Lets existing users set or change their calorie settings from the Diet tab.
struct NutritionSettingsSheet: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    // Decided once on open, so the field doesn't vanish mid-typing
    @State private var needsAge = false

    var body: some View {
        ZStack {
            Theme.pitchBlack.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Your calorie goal")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)

                    if needsAge {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age")
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                            TextField("e.g. 25", text: $viewModel.age)
                                .keyboardType(.numberPad)
                                .textFieldStyle(PumpTextFieldStyle())
                        }
                    }

                    NutritionSettingsForm(viewModel: viewModel)

                    if let targets = viewModel.nutritionTargets {
                        Text("\(targets.calories) kcal · \(targets.protein)g protein · \(targets.carbs)g carbs · \(targets.fat)g fat")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(Theme.accent)
                    } else if viewModel.heightInCm == nil || viewModel.weightInKg == nil {
                        Text("Your height or weight is missing from your profile.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                    }

                    Button(action: {
                        viewModel.saveNutritionSettings()
                        dismiss()
                    }) {
                        Text("Save").pumpButtonStyle()
                    }
                    .disabled(viewModel.nutritionTargets == nil)
                    .opacity(viewModel.nutritionTargets == nil ? 0.5 : 1)
                }
                .padding(24)
            }
        }
        .onAppear { needsAge = Int(viewModel.age) == nil }
    }
}
