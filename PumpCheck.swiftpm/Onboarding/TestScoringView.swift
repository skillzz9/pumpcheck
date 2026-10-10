import SwiftUI
import PhotosUI

struct TestScoringView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var isAnalyzing = false
    @State private var result: ScoringResult? = nil
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 250, height: 350)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Theme.cardBackground)
                                    .frame(width: 250, height: 350)
                                
                                VStack {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.taupeGrey)
                                    Text("Select Photo")
                                        .font(.headline)
                                        .foregroundColor(Theme.taupeGrey)
                                        .padding(.top, 8)
                                }
                            }
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text(selectedImageData == nil ? "Choose Photo" : "Change Photo")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                    result = nil
                                    errorMessage = nil
                                }
                            }
                        }
                        
                        if let selectedImageData {
                            Button(action: {
                                analyze(data: selectedImageData)
                            }) {
                                HStack {
                                    if isAnalyzing {
                                        ProgressView().tint(Theme.pitchBlack)
                                    }
                                    Text(isAnalyzing ? "Analyzing..." : "Analyze Physique")
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
                                Text("Score: \(String(format: "%.1f", res.score))/10")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundColor(Theme.accent)
                                
                                HStack(spacing: 12) {
                                    VStack(spacing: 4) {
                                        Text("BODY FAT")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.taupeGrey)
                                        Text(res.bodyFatEstimate.uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Theme.cardBackground)
                                    .cornerRadius(8)
                                    
                                    VStack(spacing: 4) {
                                        Text("BODY TYPE")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.taupeGrey)
                                        Text(res.bodyType.uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Theme.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Theme.cardBackground)
                                    .cornerRadius(8)
                                    
                                    VStack(spacing: 4) {
                                        Text("BEST AREA")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.taupeGrey)
                                        Text(res.bestArea.uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Theme.accent)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Theme.cardBackground)
                                    .cornerRadius(8)
                                    
                                    VStack(spacing: 4) {
                                        Text("FOCUS")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Theme.taupeGrey)
                                        Text(res.weakestArea.uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.red.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Theme.cardBackground)
                                    .cornerRadius(8)
                                }
                                .padding(.bottom, 8)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Strengths")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    
                                    ForEach(res.strengths, id: \.self) { strength in
                                        HStack(alignment: .top, spacing: 8) {
                                            Circle()
                                                .fill(Theme.accent)
                                                .frame(width: 6, height: 6)
                                                .padding(.top, 6)
                                            Text(strength)
                                                .font(.system(size: 14))
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Areas to Improve")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    
                                    ForEach(res.areasToImprove, id: \.self) { area in
                                        HStack(alignment: .top, spacing: 8) {
                                            Circle()
                                                .fill(Theme.accent)
                                                .frame(width: 6, height: 6)
                                                .padding(.top, 6)
                                            Text(area)
                                                .font(.system(size: 14))
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Action Plan: 5 Recommended Exercises")
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
            .navigationTitle("AI Scoring Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }
    
    private func analyze(data: Data) {
        guard let image = UIImage(data: data),
              let compressed = image.jpegData(compressionQuality: 0.2) else { return }
        let base64 = compressed.base64EncodedString()
        
        isAnalyzing = true
        errorMessage = nil
        result = nil
        
        Task {
            do {
                let res = try await PhysiqueScoringService.shared.analyzePhysique(imageBase64: base64, height: viewModel.height, weight: viewModel.weight)
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
