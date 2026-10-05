import sys

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "r") as f:
    content = f.read()

# Replace the state property
content = content.replace('@State private var selectedItem: PhotosPickerItem? = nil', '@State private var selectedItem: PhotosPickerItem? = nil\n    @State private var sliderValue: Double = 0')

# Extract the header and the old upload button
old_view_start = """            VStack {
                Text("Progress")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                
                // Upload button
                Button {
                    showAccuracyWarning = true
                } label: {
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
                .onChange(of: selectedItem) {"""

new_view_start = """            VStack(spacing: 0) {
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
                            let currentIndex = min(max(Int(sliderValue), 0), sortedEntries.count - 1)
                            let currentEntry = sortedEntries[currentIndex]
                            
                            if let data = Data(base64Encoded: currentEntry.photoBase64), let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1.0, contentMode: .fit)
                                    .clipped()
                            } else {
                                Rectangle()
                                    .fill(Theme.cardBackground)
                                    .aspectRatio(1.0, contentMode: .fit)
                            }
                            
                            if sortedEntries.count > 1 {
                                VStack(spacing: 4) {
                                    Slider(value: $sliderValue, in: 0...Double(sortedEntries.count - 1), step: 1.0)
                                        .tint(Theme.accent)
                                    
                                    Text(currentEntry.date.formatted(.dateTime.year().month().day()))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Theme.taupeGrey)
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
                        .onChange(of: selectedItem) {"""

content = content.replace(old_view_start, new_view_start)

# We need to remove the `ScrollView {` that was originally there since we opened it earlier.
old_scrollview = """                }
                
                ScrollView {
                    LazyVGrid"""

new_scrollview = """                }
                
                LazyVGrid"""

content = content.replace(old_scrollview, new_scrollview)

with open("PumpCheck.swiftpm/Onboarding/ProgressTab.swift", "w") as f:
    f.write(content)

