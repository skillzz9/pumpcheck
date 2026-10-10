import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// A saved meal that can be logged with one tap, e.g. "Coffee with milk".
struct QuickAdd: Identifiable, Equatable {
    var id = UUID().uuidString
    var name: String
    var emoji: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    var useCount: Int = 0

    init(id: String = UUID().uuidString, name: String, emoji: String = "", calories: Int, protein: Int, carbs: Int, fat: Int, useCount: Int = 0) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.useCount = useCount
    }

    init(from meal: MealEntry) {
        self.init(name: meal.name, calories: meal.calories, protein: meal.protein, carbs: meal.carbs, fat: meal.fat)
    }

    func makeMeal() -> MealEntry {
        MealEntry(name: name, time: .now, calories: calories, protein: protein, carbs: carbs, fat: fat)
    }
}

/// Stores quick adds at users/{uid}/quickAdds/{id}.
enum QuickAddService {
    private static func collection() -> CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return Firestore.firestore().collection("users").document(uid).collection("quickAdds")
    }

    /// Most used first.
    static func all() async throws -> [QuickAdd] {
        guard let collection = collection() else { return [] }
        let snapshot = try await collection.getDocuments()
        return snapshot.documents.map { doc in
            let data = doc.data()
            return QuickAdd(
                id: doc.documentID,
                name: data["name"] as? String ?? "Meal",
                emoji: data["emoji"] as? String ?? "",
                calories: data["calories"] as? Int ?? 0,
                protein: data["protein"] as? Int ?? 0,
                carbs: data["carbs"] as? Int ?? 0,
                fat: data["fat"] as? Int ?? 0,
                useCount: data["useCount"] as? Int ?? 0
            )
        }
        .sorted { $0.useCount != $1.useCount ? $0.useCount > $1.useCount : $0.name < $1.name }
    }

    static func save(_ quickAdd: QuickAdd) async throws {
        try await collection()?.document(quickAdd.id).setData([
            "name": quickAdd.name,
            "emoji": quickAdd.emoji,
            "calories": quickAdd.calories,
            "protein": quickAdd.protein,
            "carbs": quickAdd.carbs,
            "fat": quickAdd.fat,
            "useCount": quickAdd.useCount
        ])
    }

    static func delete(_ quickAdd: QuickAdd) async throws {
        try await collection()?.document(quickAdd.id).delete()
    }

    static func recordUse(_ quickAdd: QuickAdd) async throws {
        try await collection()?.document(quickAdd.id).updateData(["useCount": FieldValue.increment(Int64(1))])
    }
}

// MARK: - Chip row

struct QuickAddRow: View {
    let quickAdds: [QuickAdd]
    let onLog: (QuickAdd) -> Void
    let onEdit: (QuickAdd) -> Void
    let onDelete: (QuickAdd) -> Void
    let onNew: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickAdds) { quickAdd in
                    Button(action: { onLog(quickAdd) }) {
                        HStack(spacing: 6) {
                            if !quickAdd.emoji.isEmpty {
                                Text(quickAdd.emoji)
                            }
                            Text(quickAdd.name)
                                .foregroundColor(Theme.textPrimary)
                                .lineLimit(1)
                            Text("· \(quickAdd.calories)")
                                .foregroundColor(Theme.textSecondary)
                                .monospacedDigit()
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Theme.cardBackground)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button { onEdit(quickAdd) } label: { Label("Edit", systemImage: "pencil") }
                        Button(role: .destructive) { onDelete(quickAdd) } label: { Label("Delete", systemImage: "trash") }
                    }
                }

                Button(action: onNew) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("New")
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .overlay(Capsule().stroke(Theme.accent.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Editor

/// Creates or edits a quick add, by typing the numbers or having the AI estimate them from a description.
struct QuickAddEditor: View {
    let existing: QuickAdd?
    /// Logs a one-off meal instead of saving a quick add
    var logsMeal = false
    let onSave: (QuickAdd) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var isEstimating = false
    @State private var errorMessage: String?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && Self.amount(calories) != nil
    }

    /// Reads "3.5", "3,5" or "8g" as a whole number, so typed decimals and units aren't lost as 0.
    static func amount(_ text: String) -> Int? {
        let cleaned = text.replacingOccurrences(of: ",", with: ".").filter { $0.isNumber || $0 == "." }
        return Double(cleaned).map { Int($0.rounded()) }
    }

    var body: some View {
        ZStack {
            Theme.pitchBlack.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(logsMeal ? "Log Meal" : (existing == nil ? "New Quick Add" : "Edit Quick Add"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)

                    HStack(spacing: 12) {
                        EmojiField(emoji: $emoji)
                            .frame(width: 56, height: 56)
                        TextField("e.g. Coffee with milk", text: $name)
                            .textFieldStyle(PumpTextFieldStyle())
                    }

                    Button(action: estimate) {
                        Group {
                            if isEstimating {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Theme.paleSky))
                            } else {
                                Label("Estimate with AI", systemImage: "sparkles")
                            }
                        }
                        .pumpButtonStyle(isPrimary: false)
                    }
                    .disabled(isEstimating || name.trimmingCharacters(in: .whitespaces).isEmpty)

                    Text("Or enter the numbers yourself:")
                        .font(.subheadline)
                        .foregroundColor(Theme.textSecondary)

                    HStack(spacing: 10) {
                        numberField("kcal", text: $calories)
                        numberField("Protein g", text: $protein)
                        numberField("Carbs g", text: $carbs)
                        numberField("Fat g", text: $fat)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.accent)
                    }

                    Button(action: save) {
                        Text(logsMeal ? "Add to Log" : "Save").pumpButtonStyle()
                    }
                    .disabled(!canSave || isEstimating)
                    .opacity(canSave ? 1 : 0.5)

                    Button(action: { dismiss() }) {
                        Text("Cancel").pumpButtonStyle(isPrimary: false)
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            guard let existing else { return }
            name = existing.name
            emoji = existing.emoji
            calories = String(existing.calories)
            protein = String(existing.protein)
            carbs = String(existing.carbs)
            fat = String(existing.fat)
        }
    }

    private func numberField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textSecondary)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(Theme.cardBackground)
                .cornerRadius(10)
        }
    }

    private func estimate() {
        errorMessage = nil
        isEstimating = true
        Task {
            do {
                let totals = try await MealScanService.shared.estimate(description: name)
                calories = String(totals.calories)
                protein = String(totals.protein)
                carbs = String(totals.carbs)
                fat = String(totals.fat)
            } catch {
                errorMessage = error.localizedDescription
            }
            isEstimating = false
        }
    }

    private func save() {
        onSave(QuickAdd(
            id: existing?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            emoji: emoji,
            calories: Self.amount(calories) ?? 0,
            protein: Self.amount(protein) ?? 0,
            carbs: Self.amount(carbs) ?? 0,
            fat: Self.amount(fat) ?? 0,
            useCount: existing?.useCount ?? 0
        ))
        dismiss()
    }
}

// MARK: - Emoji field

/// A single-emoji field that opens the emoji keyboard; shows a placeholder icon when empty.
struct EmojiField: View {
    @Binding var emoji: String

    var body: some View {
        ZStack {
            Theme.textBoxBlue
            if emoji.isEmpty {
                Image(systemName: "face.smiling")
                    .font(.system(size: 22))
                    .foregroundColor(Theme.textSecondary)
                    .allowsHitTesting(false)
            }
            EmojiTextFieldRepresentable(emoji: $emoji)
        }
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1))
    }
}

/// UITextField that asks for the emoji keyboard instead of the user's default one.
final class EmojiUITextField: UITextField {
    override var textInputContextIdentifier: String? { "" }

    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" } ?? super.textInputMode
    }
}

struct EmojiTextFieldRepresentable: UIViewRepresentable {
    @Binding var emoji: String

    func makeUIView(context: Context) -> EmojiUITextField {
        let field = EmojiUITextField()
        field.textAlignment = .center
        field.font = .systemFont(ofSize: 28)
        field.tintColor = .clear
        field.backgroundColor = .clear
        field.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        return field
    }

    func updateUIView(_ field: EmojiUITextField, context: Context) {
        if field.text != emoji { field.text = emoji }
    }

    func makeCoordinator() -> Coordinator { Coordinator(emoji: $emoji) }

    final class Coordinator: NSObject {
        let emoji: Binding<String>
        init(emoji: Binding<String>) { self.emoji = emoji }

        /// Keeps only the newest emoji, so picking another one replaces it and backspace clears it.
        @objc func textChanged(_ field: UITextField) {
            let latest = (field.text ?? "").last { character in
                character.unicodeScalars.contains { $0.properties.isEmojiPresentation }
                    || (character.unicodeScalars.first?.properties.isEmoji == true && character.unicodeScalars.count > 1)
            }
            let value = latest.map(String.init) ?? ""
            field.text = value
            emoji.wrappedValue = value
        }
    }
}
