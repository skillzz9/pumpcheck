import SwiftUI
import PhotosUI
import ImageIO

struct ProgressEntry: Identifiable, Codable {
    var id: String = UUID().uuidString
    var date: Date = Date()
    var photoBase64: String
    var weight: String
    var lifts: [LiftRecord]
}

struct ProgressTab: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var sliderValue: Double = 0
    @AppStorage(ProgressSliderMode.storageKey) private var sliderMode: ProgressSliderMode = .flicker
    @State private var selectedImageData: Data? = nil
    @State private var showLogModal = false
    @State private var isProcessingPhoto = false
    @State private var selectedEntry: ProgressEntry? = nil
    @State private var showAccuracyWarning = false
    
    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    if isProcessingPhoto {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                    } else {
                        Button {
                            showAccuracyWarning = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Theme.accent)
                                .padding(8)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                ScrollView {
                    // New Large Photo Slider
                    let sortedEntries = viewModel.progressEntries.sorted(by: { $0.date < $1.date })
                    if !sortedEntries.isEmpty {
                        VStack(spacing: 0) {
                            let currentIndex = min(max(Int(round(sliderValue)), 0), sortedEntries.count - 1)
                            let currentEntry = sortedEntries[currentIndex]
                            
                            ProgressPhotoStack(photos: sortedEntries.map(\.photoBase64), sliderValue: sliderValue, mode: sliderMode)
                                .overlay(alignment: .topTrailing) {
                                    if sortedEntries.count > 1 {
                                        ProgressSliderModeToggle(mode: $sliderMode)
                                    }
                                }
                            
                            if sortedEntries.count > 1 {
                                VStack(spacing: 8) {
                                    GeometryReader { geo in
                                        let trackWidth = geo.size.width - 28
                                        let percentage = CGFloat(sliderValue / Double(sortedEntries.count - 1))
                                        let thumbX = 14 + (percentage * trackWidth)
                                        
                                        Text(currentEntry.date.formatted(.dateTime.year().month().day()))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.taupeGrey)
                                            .position(x: thumbX, y: geo.size.height / 2)
                                    }
                                    .frame(height: 14)
                                    
                                    Slider(value: $sliderValue, in: 0...Double(sortedEntries.count - 1), onEditingChanged: { editing in
                                        if !editing && sliderMode == .flicker {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                sliderValue = round(sliderValue)
                                            }
                                        }
                                    })
                                    .tint(Theme.accent)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Theme.pitchBlack)
                            } else {
                                Text(currentEntry.date.formatted(.dateTime.year().month().day()))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Theme.taupeGrey)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.pitchBlack)
                            }
                        }
                        .padding(.bottom, 16)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.taupeGrey.opacity(0.5))
                            Text("No progress photos yet. Tap + to upload.")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    }
                    
                    // The .onChange for uploading photo must be attached somewhere.
                    // We'll attach it to the VStack or ScrollView below.
                    EmptyView()
                        .onChange(of: selectedItem) { _, newItem in
                    guard let newItem = newItem else { return }
                    isProcessingPhoto = true
                    Task {
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self) {
                                await MainActor.run {
                                    selectedImageData = data
                                    isProcessingPhoto = false
                                    showLogModal = true
                                }
                            } else {
                                await MainActor.run { isProcessingPhoto = false }
                            }
                        } catch {
                            await MainActor.run { isProcessingPhoto = false }
                        }
                    }
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(viewModel.progressEntries.reversed()) { entry in
                            Button(action: {
                                selectedEntry = entry
                            }) {
                                ZStack(alignment: .bottomLeading) {
                                    if let uiImage = ImageCache.decode(base64: entry.photoBase64) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .aspectRatio(9.0 / 16.0, contentMode: .fit)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Theme.cardBackground)
                                            .aspectRatio(9.0 / 16.0, contentMode: .fit)
                                    }
                                    
                                    LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .center)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.date.formatted(.dateTime.day().month()))
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        if !entry.weight.isEmpty {
                                            Text("\(entry.weight)\(viewModel.isWeightKg ? "kg" : "lb")")
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundColor(Theme.accent)
                                        }
                                    }
                                    .padding(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
            }
        }
        .sheet(isPresented: $showAccuracyWarning) {
            AccuracyWarningModal(selectedItem: $selectedItem)
        }
        .sheet(item: $selectedEntry) { entry in
            ProgressDetailView(
                initialEntry: entry,
                allEntries: viewModel.progressEntries,
                isWeightKg: viewModel.isWeightKg,
                onDismiss: { selectedEntry = nil },
                onDelete: { try await viewModel.deleteProgressEntry($0) }
            )
        }
        .sheet(isPresented: $showLogModal) {
            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                LogProgressModal(
                    viewModel: viewModel,
                    uiImage: uiImage,
                    initialDate: extractDate(from: data) ?? Date(),
                    onSave: {
                        selectedItem = nil
                        selectedImageData = nil
                        showLogModal = false
                    },
                    onCancel: {
                        selectedItem = nil
                        selectedImageData = nil
                        showLogModal = false
                    }
                )
            }
        }
    }
}


struct AccuracyWarningModal: View {
    @Binding var selectedItem: PhotosPickerItem?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Theme.pitchBlack.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Image(systemName: "camera.metering.spot")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.accent)
                
                Text("Consistency is Key")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                
                Text("Make sure you take a picture in the same lighting and the same place to make the AI analysis as accurate as possible.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
                
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    Text("I understand")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.pitchBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent)
                        .cornerRadius(16)
                        .padding(.horizontal, 32)
                }
                .onChange(of: selectedItem) { _, newItem in
                    if newItem != nil {
                        dismiss()
                    }
                }
                
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Theme.textSecondary)
                .padding(.top, -8)
            }
        }
        .presentationDetents([.fraction(0.6)])
    }
}

func extractDate(from data: Data) -> Date? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    guard let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else { return nil }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
    
    if let exif = metadata["{Exif}"] as? [String: Any],
       let dateTimeOriginal = exif["DateTimeOriginal"] as? String {
        return formatter.date(from: dateTimeOriginal)
    }
    
    if let tiff = metadata["{TIFF}"] as? [String: Any],
       let dateTime = tiff["DateTime"] as? String {
        return formatter.date(from: dateTime)
    }
    
    return nil
}
