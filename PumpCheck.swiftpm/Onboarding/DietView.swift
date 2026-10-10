import SwiftUI
import Charts
import PhotosUI

struct MealEntry: Identifiable {
    var id = UUID().uuidString
    let name: String
    let time: Date
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

struct DietView: View {
    @Bindable var viewModel: OnboardingViewModel

    // Defaults shown until the user's calorie settings are complete
    private var targets: NutritionTargets {
        viewModel.nutritionTargets ?? NutritionTargets(calories: 2500, protein: 160, carbs: 280, fat: 70)
    }
    private var calorieGoal: Int { targets.calories }
    private var proteinGoal: Int { targets.protein }
    private var carbsGoal: Int { targets.carbs }
    private var fatGoal: Int { targets.fat }
    @State private var showNutritionSettings = false
    @State private var showHistory = false
    @State private var summaries: [DailySummary] = []
    @State private var quickAdds: [QuickAdd] = []
    @State private var editingQuickAdd: QuickAdd?
    @State private var showNewQuickAdd = false
    @State private var undoMeal: MealEntry?
    @State private var showBarcode = false
    @State private var barcodeOutcome: BarcodeOutcome?
    @State private var showManualMeal = false
    @State private var meals: [MealEntry] = []
    @State private var saveError: String?
    @Environment(\.scenePhase) private var scenePhase

    @State private var showAddOptions = false
    @State private var showCamera = false
    @State private var showLibrary = false
    @State private var libraryItem: PhotosPickerItem?
    @State private var pendingPhoto: PendingMealPhoto?
    @State private var capturedPhoto: UIImage?

    private var caloriesEaten: Int { meals.reduce(0) { $0 + $1.calories } }
    private var caloriesLeft: Int { max(calorieGoal - caloriesEaten, 0) }
    private var caloriesOver: Int { max(caloriesEaten - calorieGoal, 0) }
    /// Going over only counts as a problem when cutting
    private var isOverOnCut: Bool { viewModel.dietGoal == DietGoal.lose.rawValue && caloriesOver > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.pitchBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if viewModel.nutritionTargets == nil {
                            setupCard
                        }
                        calorieCard
                        mealLog
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 120)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(Theme.accent)
                        Text("\(DailyCalorieService.currentStreak(summaries))")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .monospacedDigit()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showHistory = true }) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                CalorieHistoryView(summaries: summaries, currentGoal: calorieGoal)
            }
            .confirmationDialog("Add Meal", isPresented: $showAddOptions) {
                Button("Scan Barcode") { showBarcode = true }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") { showCamera = true }
                }
                Button("Choose from Library") { showLibrary = true }
            }
            // Show the scan sheet only once the camera has fully closed
            .fullScreenCover(isPresented: $showCamera, onDismiss: {
                if let image = capturedPhoto {
                    pendingPhoto = PendingMealPhoto(image: image)
                    capturedPhoto = nil
                }
            }) {
                CameraPicker { image in
                    capturedPhoto = image
                }
                .ignoresSafeArea()
            }
            .photosPicker(isPresented: $showLibrary, selection: $libraryItem, matching: .images)
            .onChange(of: libraryItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        pendingPhoto = PendingMealPhoto(image: image)
                    }
                    libraryItem = nil
                }
            }
            .sheet(item: $pendingPhoto) { pending in
                MealScanSheet(photo: pending.image) { meal, saveAsQuickAdd in
                    add(meal)
                    if saveAsQuickAdd { saveQuickAdd(QuickAdd(from: meal)) }
                }
            }
            // Fallbacks open only once the barcode screen has fully closed
            .fullScreenCover(isPresented: $showBarcode, onDismiss: handleBarcodeOutcome) {
                BarcodeFlowView { barcodeOutcome = $0 }
            }
            .sheet(isPresented: $showManualMeal) {
                QuickAddEditor(existing: nil, logsMeal: true) { add($0.makeMeal()) }
            }
            .sheet(isPresented: $showNewQuickAdd) {
                QuickAddEditor(existing: nil) { saveQuickAdd($0) }
            }
            .sheet(item: $editingQuickAdd) { quickAdd in
                QuickAddEditor(existing: quickAdd) { saveQuickAdd($0) }
            }
            .overlay(alignment: .bottom) {
                if let undoMeal {
                    undoBanner(undoMeal)
                        .padding(.bottom, 110)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .alert("Couldn't save", isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "")
            }
            .sheet(isPresented: $showNutritionSettings) {
                NutritionSettingsSheet(viewModel: viewModel)
            }
            .task {
                await loadMeals()
                await loadQuickAdds()
            }
            // Reload when returning to the app, so a new day starts with an empty log
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await loadMeals() } }
            }
        }
    }

    // MARK: - Calorie ring

    private var calorieCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Chart {
                    if isOverOnCut {
                        // Loops back around from the top: the overage in red over the full ring
                        let overLap = min(caloriesOver, calorieGoal)
                        SectorMark(angle: .value("Over", overLap), innerRadius: .ratio(0.82), angularInset: 1.5)
                            .foregroundStyle(Theme.overLimit)
                            .cornerRadius(6)
                        SectorMark(angle: .value("Eaten", calorieGoal - overLap), innerRadius: .ratio(0.82), angularInset: 1.5)
                            .foregroundStyle(Theme.paleSky.opacity(0.12))
                            .cornerRadius(6)
                    } else {
                        SectorMark(angle: .value("Eaten", min(caloriesEaten, calorieGoal)), innerRadius: .ratio(0.82), angularInset: 1.5)
                            .foregroundStyle(Theme.paleSky.opacity(0.12))
                            .cornerRadius(6)
                        SectorMark(angle: .value("Remaining", caloriesLeft), innerRadius: .ratio(0.82), angularInset: 1.5)
                            .foregroundStyle(Theme.pitchBlack)
                            .cornerRadius(6)
                    }
                }
                .chartLegend(.hidden)

                VStack(spacing: 2) {
                    Text("\(isOverOnCut ? caloriesOver : caloriesLeft)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(isOverOnCut ? Theme.overLimit : Theme.textPrimary)
                        .monospacedDigit()
                    Text(isOverOnCut ? "kcal over" : "kcal left")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(isOverOnCut ? Theme.overLimit : Theme.textSecondary)
                }
            }
            .frame(width: 200, height: 200)

            Divider().overlay(Theme.taupeGrey.opacity(0.15))

            macrosRow
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground)
        .cornerRadius(20)
        .contentShape(Rectangle())
        .onTapGesture { showNutritionSettings = true }
    }

    private var setupCard: some View {
        Button(action: { showNutritionSettings = true }) {
            HStack(spacing: 12) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set up your calorie goal")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    Text("Tell us how active you are to personalize your targets.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(16)
            .background(Theme.cardBackground)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Macros

    private var macrosRow: some View {
        HStack(spacing: 8) {
            MacroRing(name: "Protein", eaten: meals.reduce(0) { $0 + $1.protein }, goal: proteinGoal, color: Theme.accent)
            MacroRing(name: "Carbs", eaten: meals.reduce(0) { $0 + $1.carbs }, goal: carbsGoal, color: Theme.paleSky)
            MacroRing(name: "Fats", eaten: meals.reduce(0) { $0 + $1.fat }, goal: fatGoal, color: Theme.darkCoffee)
        }
    }

    // MARK: - Meal log

    private var mealLog: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("Meal Log")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)

                Button(action: { showAddOptions = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Theme.pitchBlack)
                        .frame(width: 24, height: 24)
                        .background(Theme.accent)
                        .clipShape(Circle())
                }

                Spacer()
            }

            QuickAddRow(
                quickAdds: quickAdds,
                onLog: logQuickAdd,
                onEdit: { editingQuickAdd = $0 },
                onDelete: deleteQuickAdd,
                onNew: { showNewQuickAdd = true }
            )

            if meals.isEmpty {
                Text("No meals logged yet today.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }

            ForEach(meals.sorted(by: { $0.time < $1.time })) { meal in
                MealRow(meal: meal)
                    .contextMenu {
                        Button { saveQuickAdd(QuickAdd(from: meal)) } label: {
                            Label("Save as Quick Add", systemImage: "bolt.fill")
                        }
                        Button(role: .destructive) { delete(meal) } label: {
                            Label("Delete Meal", systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Barcode

    private func handleBarcodeOutcome() {
        guard let outcome = barcodeOutcome else { return }
        barcodeOutcome = nil
        switch outcome {
        case .logged(let meal, let saveAsQuickAdd):
            add(meal)
            if saveAsQuickAdd { saveQuickAdd(QuickAdd(from: meal)) }
        case .photographLabel:
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                showCamera = true
            } else {
                showLibrary = true
            }
        case .enterManually:
            showManualMeal = true
        }
    }

    // MARK: - Quick adds

    private func loadQuickAdds() async {
        do {
            quickAdds = try await QuickAddService.all()
        } catch {
            print("Failed to load quick adds: \(error)")
        }
    }

    private func logQuickAdd(_ quickAdd: QuickAdd) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        let meal = quickAdd.makeMeal()
        add(meal)
        showUndo(for: meal)
        Task {
            try? await QuickAddService.recordUse(quickAdd)
            if let index = quickAdds.firstIndex(where: { $0.id == quickAdd.id }) {
                quickAdds[index].useCount += 1
            }
        }
    }

    private func saveQuickAdd(_ quickAdd: QuickAdd) {
        let previous = quickAdds.first { $0.id == quickAdd.id }
        if let index = quickAdds.firstIndex(where: { $0.id == quickAdd.id }) {
            quickAdds[index] = quickAdd
        } else {
            quickAdds.append(quickAdd)
        }
        Task {
            do {
                try await QuickAddService.save(quickAdd)
            } catch {
                // Put an edited quick add back as it was; drop a new one
                if let previous, let index = quickAdds.firstIndex(where: { $0.id == quickAdd.id }) {
                    quickAdds[index] = previous
                } else {
                    quickAdds.removeAll { $0.id == quickAdd.id }
                }
                saveError = error.localizedDescription
            }
        }
    }

    private func deleteQuickAdd(_ quickAdd: QuickAdd) {
        quickAdds.removeAll { $0.id == quickAdd.id }
        Task { try? await QuickAddService.delete(quickAdd) }
    }

    private func showUndo(for meal: MealEntry) {
        withAnimation(.spring(response: 0.3)) { undoMeal = meal }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            if undoMeal?.id == meal.id {
                withAnimation { undoMeal = nil }
            }
        }
    }

    private func undoBanner(_ meal: MealEntry) -> some View {
        HStack {
            Text("Logged \(meal.name)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
            Spacer()
            Button("Undo") {
                delete(meal)
                withAnimation { undoMeal = nil }
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.textBoxBlue)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
        .padding(.horizontal, 24)
    }

    // MARK: - Persistence

    private func loadMeals() async {
        do {
            meals = try await MealLogService.meals(on: .now)
            if !meals.isEmpty {
                await syncToday()
            } else {
                await loadSummaries()
            }
        } catch {
            print("Failed to load meals: \(error)")
        }
    }

    /// Records today's running total, so the day is already saved when midnight hits.
    private func syncToday() async {
        do {
            try await DailyCalorieService.save(day: .now, meals: meals, calorieGoal: calorieGoal, dietGoal: viewModel.dietGoal)
        } catch {
            print("Failed to save daily summary: \(error)")
        }
        await loadSummaries()
    }

    private func loadSummaries() async {
        do {
            summaries = try await DailyCalorieService.recent()
        } catch {
            print("Failed to load daily summaries: \(error)")
        }
    }

    private func add(_ meal: MealEntry) {
        meals.append(meal)
        Task {
            do {
                try await MealLogService.save(meal)
                await syncToday()
            } catch {
                meals.removeAll { $0.id == meal.id }
                saveError = error.localizedDescription
            }
        }
    }

    private func delete(_ meal: MealEntry) {
        meals.removeAll { $0.id == meal.id }
        Task {
            do {
                try await MealLogService.delete(meal)
                await syncToday()
            } catch {
                meals.append(meal)
                saveError = error.localizedDescription
            }
        }
    }
}

struct MacroRing: View {
    let name: String
    let eaten: Int
    let goal: Int
    let color: Color

    var body: some View {
        let progress = goal > 0 ? min(Double(eaten) / Double(goal), 1) : 0
        // Over the goal: the ring is full, and the overage laps back around in red
        let overProgress = goal > 0 ? min(max(Double(eaten - goal), 0) / Double(goal), 1) : 0
        let isOver = overProgress > 0

        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Theme.pitchBlack.opacity(0.6), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: isOver ? .butt : .round))
                    .rotationEffect(.degrees(-90))
                if isOver {
                    Circle()
                        .trim(from: 0, to: overProgress)
                        .stroke(Theme.overLimit, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }

                Text("\(eaten)g")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(isOver ? Theme.overLimit : Theme.textPrimary)
                    .monospacedDigit()
            }
            .frame(width: 40, height: 40)
            .padding(2)

            Text("\(name) · \(goal)g")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MealRow: View {
    let meal: MealEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(meal.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(meal.time.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }

            HStack(spacing: 0) {
                stat(meal.calories, "kcal", Theme.textPrimary)
                stat(meal.protein, "protein", Theme.accent)
                stat(meal.carbs, "carbs", Theme.paleSky)
                stat(meal.fat, "fat", Theme.darkCoffee)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.cardBackground)
        .cornerRadius(16)
    }

    private func stat(_ value: Int, _ label: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label == "kcal" ? "\(value)" : "\(value)g")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
