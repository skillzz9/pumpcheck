import SwiftUI
import VisionKit
import AVFoundation

/// What the barcode flow hands back to the Diet tab when it closes.
enum BarcodeOutcome {
    case logged(MealEntry, saveAsQuickAdd: Bool)
    case photographLabel
    case enterManually
}

/// Scan → look up → choose amount → log. Falls back to a label photo or manual entry if not found.
struct BarcodeFlowView: View {
    let onFinish: (BarcodeOutcome) -> Void

    private enum Stage: Equatable {
        case scanning, typing, lookingUp, notFound, product
    }

    @Environment(\.dismiss) private var dismiss
    @State private var stage: Stage = DataScannerViewController.isSupported ? .scanning : .typing
    @State private var typedCode = ""
    @State private var product: BarcodeProduct?
    @State private var errorMessage: String?
    @State private var torchOn = false

    var body: some View {
        ZStack {
            Theme.pitchBlack.ignoresSafeArea()

            switch stage {
            case .scanning: scannerView
            case .typing: typingView
            case .lookingUp:
                VStack(spacing: 12) {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Theme.accent)).scaleEffect(1.3)
                    Text("Looking up product...")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                }
            case .notFound: notFoundView
            case .product:
                if let product {
                    BarcodeProductView(product: product, onCancel: { close() }) { meal, saveAsQuickAdd in
                        finish(.logged(meal, saveAsQuickAdd: saveAsQuickAdd))
                    }
                }
            }
        }
        .onDisappear { setTorch(false) }
    }

    // MARK: - Scanning

    private var scannerView: some View {
        ZStack {
            BarcodeScannerRepresentable { code in lookUp(code) }
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.accent, lineWidth: 3)
                .frame(width: 280, height: 160)
                .allowsHitTesting(false)

            VStack {
                HStack {
                    closeButton
                    Spacer()
                    Button(action: { torchOn.toggle(); setTorch(torchOn) }) {
                        Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(Theme.pitchBlack.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                Text("Point the camera at a barcode")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.pitchBlack.opacity(0.7))
                    .clipShape(Capsule())

                Button(action: { stage = .typing }) {
                    Text("Enter barcode").pumpButtonStyle(isPrimary: false)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
    }

    private var typingView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Spacer(); closeButton }
            Text("Enter barcode")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text("The number printed under the barcode.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textSecondary)

            TextField("e.g. 9300633603102", text: $typedCode)
                .keyboardType(.numberPad)
                .textFieldStyle(PumpTextFieldStyle())

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.accent)
            }

            Button(action: { lookUp(typedCode) }) {
                Text("Look Up").pumpButtonStyle()
            }
            .disabled(typedCode.filter(\.isNumber).count < 6)

            if DataScannerViewController.isSupported {
                Button(action: { stage = .scanning }) {
                    Text("Scan with camera").pumpButtonStyle(isPrimary: false)
                }
            }
            Spacer()
        }
        .padding(24)
    }

    private var notFoundView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Spacer(); closeButton }
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 44))
                .foregroundColor(Theme.accent)
            Text("Product not found")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text("It isn't in the food databases yet. Snap the nutrition label instead, or enter it yourself.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textSecondary)

            Button(action: { finish(.photographLabel) }) {
                Label("Photo of the nutrition label", systemImage: "camera.fill").pumpButtonStyle()
            }
            Button(action: { finish(.enterManually) }) {
                Text("Enter manually").pumpButtonStyle(isPrimary: false)
            }
            Button(action: { stage = DataScannerViewController.isSupported ? .scanning : .typing }) {
                Text("Try another barcode")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.accent)
                    .frame(maxWidth: .infinity)
            }
            Spacer()
        }
        .padding(24)
    }

    private var closeButton: some View {
        Button(action: close) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textPrimary)
                .frame(width: 44, height: 44)
                .background(Theme.pitchBlack.opacity(0.7))
                .clipShape(Circle())
        }
    }

    // MARK: - Actions

    private func lookUp(_ code: String) {
        guard stage != .lookingUp else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        setTorch(false)
        errorMessage = nil
        stage = .lookingUp
        Task {
            do {
                if let found = try await BarcodeService.lookup(code) {
                    product = found
                    stage = .product
                } else {
                    stage = .notFound
                }
            } catch {
                errorMessage = "Couldn't reach the food databases. Check your connection and try again."
                typedCode = code.filter(\.isNumber)
                stage = .typing
            }
        }
    }

    private func finish(_ outcome: BarcodeOutcome) {
        onFinish(outcome)
        dismiss()
    }

    private func close() { dismiss() }

    private func setTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch,
              (try? device.lockForConfiguration()) != nil else { return }
        device.torchMode = on ? .on : .off
        device.unlockForConfiguration()
    }
}

// MARK: - Product card

struct BarcodeProductView: View {
    let product: BarcodeProduct
    let onCancel: () -> Void
    let onAdd: (MealEntry, Bool) -> Void

    @State private var useServings: Bool
    @State private var servings: Double = 1
    @State private var gramsText: String
    @State private var saveAsQuickAdd = false

    init(product: BarcodeProduct, onCancel: @escaping () -> Void, onAdd: @escaping (MealEntry, Bool) -> Void) {
        self.product = product
        self.onCancel = onCancel
        self.onAdd = onAdd
        _useServings = State(initialValue: product.servingGrams != nil)
        _gramsText = State(initialValue: EditableComponent.format(product.servingGrams ?? 100))
    }

    private var grams: Double {
        if useServings, let serving = product.servingGrams { return serving * servings }
        return max(Double(gramsText.replacingOccurrences(of: ",", with: ".")) ?? 0, 0)
    }

    private func amount(_ per100: Double) -> Int { Int((per100 * grams / 100).rounded()) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    if !product.brand.isEmpty {
                        Text(product.brand.uppercased())
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.accent)
                    }
                    Text(product.name)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    if let label = product.servingLabel, !label.isEmpty {
                        Text("Serving: \(label)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                HStack(spacing: 0) {
                    stat("\(amount(product.calories))", "kcal", Theme.textPrimary)
                    stat("\(amount(product.protein))g", "protein", Theme.accent)
                    stat("\(amount(product.carbs))g", "carbs", Theme.paleSky)
                    stat("\(amount(product.fat))g", "fat", Theme.darkCoffee)
                }
                .padding(16)
                .background(Theme.cardBackground)
                .cornerRadius(16)

                VStack(alignment: .leading, spacing: 12) {
                    Text("How much?")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)

                    if product.servingGrams != nil {
                        Picker("Unit", selection: $useServings) {
                            Text("Servings").tag(true)
                            Text("Grams").tag(false)
                        }
                        .pickerStyle(.segmented)
                    }

                    if useServings {
                        HStack(spacing: 16) {
                            stepButton("minus") { servings = max(servings - 0.5, 0.5) }
                            Text("\(EditableComponent.format(servings)) serving\(servings == 1 ? "" : "s")")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                                .frame(minWidth: 120)
                            stepButton("plus") { servings += 0.5 }
                            Spacer()
                            Text("\(EditableComponent.format(grams))g")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.textSecondary)
                        }
                    } else {
                        HStack {
                            TextField("100", text: $gramsText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(PumpTextFieldStyle())
                            Text("g")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }

                Toggle(isOn: $saveAsQuickAdd) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Save as Quick Add")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        Text("Log this amount again with one tap")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .tint(Theme.accent)
                .padding(14)
                .background(Theme.cardBackground)
                .cornerRadius(16)

                Button(action: add) {
                    Text("Add to Log").pumpButtonStyle()
                }
                .disabled(grams <= 0)

                Button(action: onCancel) {
                    Text("Cancel").pumpButtonStyle(isPrimary: false)
                }
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func add() {
        let name = product.brand.isEmpty ? product.name : "\(product.brand) \(product.name)"
        onAdd(MealEntry(
            name: name,
            time: .now,
            calories: amount(product.calories),
            protein: amount(product.protein),
            carbs: amount(product.carbs),
            fat: amount(product.fat)
        ), saveAsQuickAdd)
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

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Theme.textPrimary)
                .frame(width: 40, height: 40)
                .background(Theme.cardBackground)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Camera scanner

/// Live barcode detection with VisionKit; reports the first barcode it reads.
struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    let onFound: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce, .code128, .itf14])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        if !scanner.isScanning { try? scanner.startScanning() }
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        scanner.stopScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onFound: onFound) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onFound: (String) -> Void
        private var hasReported = false
        init(onFound: @escaping (String) -> Void) { self.onFound = onFound }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !hasReported else { return }
            for item in addedItems {
                if case .barcode(let barcode) = item, let code = barcode.payloadStringValue {
                    hasReported = true
                    onFound(code)
                    return
                }
            }
        }
    }
}
