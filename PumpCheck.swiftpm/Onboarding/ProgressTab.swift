import SwiftUI
import PhotosUI

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
    @State private var selectedImageData: Data? = nil
    @State private var showLogModal = false
    @State private var isProcessingPhoto = false
    @State private var selectedEntry: ProgressEntry? = nil
    
    var body: some View {
        ZStack {
            Theme.bgGradient.ignoresSafeArea()
            
            VStack {
                Text("Progress")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                
                // Upload button
                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                    VStack(spacing: 12) {
                        if isProcessingPhoto {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Theme.accent))
                                .scaleEffect(1.5)
                            Text("Processing...")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .padding(.top, 8)
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 32))
                            Text("Upload Most Recent Physique")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                    }
                    .foregroundColor(Theme.paleSky)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(Theme.textBoxBlue)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.accent.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
                .disabled(isProcessingPhoto)
                .padding(.horizontal, 24)
                .padding(.top, 16)
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
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(viewModel.progressEntries.reversed()) { entry in
                            Button(action: {
                                selectedEntry = entry
                            }) {
                                ZStack(alignment: .bottomLeading) {
                                    if let data = Data(base64Encoded: entry.photoBase64), let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(minWidth: 0, maxWidth: .infinity)
                                            .aspectRatio(1, contentMode: .fit)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Theme.cardBackground)
                                            .aspectRatio(1, contentMode: .fit)
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
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            ProgressDetailView(initialEntry: entry, allEntries: viewModel.progressEntries, isWeightKg: viewModel.isWeightKg) { selectedEntry = nil }
        }
        .sheet(isPresented: $showLogModal) {
            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                LogProgressModal(
                    viewModel: viewModel,
                    uiImage: uiImage,
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
