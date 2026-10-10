import sys

with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "r") as f:
    content = f.read()

old_preview = """                        // Image Preview (4:5 Cropper)
                        Color.clear
                            .aspectRatio(4.0 / 5.0, contentMode: .fit)
                            .overlay(
                                GeometryReader { geo in
                                    ZStack {
                                        Theme.pitchBlack
                                        
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .offset(offset)
                                            .scaleEffect(scale)
                                            .gesture(
                                                SimultaneousGesture(
                                                    MagnificationGesture()
                                                        .onChanged { val in scale = max(1.0, lastScale * val) }
                                                        .onEnded { val in lastScale = scale },
                                                    DragGesture()
                                                        .onChanged { val in 
                                                            offset = CGSize(
                                                                width: lastOffset.width + val.translation.width,
                                                                height: lastOffset.height + val.translation.height
                                                            )
                                                        }
                                                        .onEnded { val in lastOffset = offset }
                                                )
                                            )
                                    }
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipped()
                                    .onAppear { cropSize = geo.size }
                                    .onChange(of: geo.size) { _, newSize in cropSize = newSize }
                                }
                            )
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 2))
                            .padding(.horizontal, 24)
                            .padding(.top, 24)"""

new_preview = """                        // Image Preview (9:16 Cropper)
                        VStack(spacing: 16) {
                            Color.clear
                                .aspectRatio(9.0 / 16.0, contentMode: .fit)
                                .overlay(
                                    GeometryReader { geo in
                                        ZStack {
                                            Theme.pitchBlack
                                            
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .offset(offset)
                                                .scaleEffect(scale)
                                                .gesture(
                                                    SimultaneousGesture(
                                                        MagnificationGesture()
                                                            .onChanged { val in scale = max(1.0, lastScale * val) }
                                                            .onEnded { val in lastScale = scale },
                                                        DragGesture()
                                                            .onChanged { val in 
                                                                offset = CGSize(
                                                                    width: lastOffset.width + val.translation.width,
                                                                    height: lastOffset.height + val.translation.height
                                                                )
                                                            }
                                                            .onEnded { val in lastOffset = offset }
                                                    )
                                                )
                                        }
                                        .frame(width: geo.size.width, height: geo.size.height)
                                        .clipped()
                                        .onAppear { cropSize = geo.size }
                                        .onChange(of: geo.size) { _, newSize in cropSize = newSize }
                                    }
                                )
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 2))
                                .padding(.horizontal, 48) // A bit more padding so it doesn't take up the whole screen height
                            
                            // Zoom Slider for Simulator
                            HStack {
                                Image(systemName: "minus.magnifyingglass")
                                    .foregroundColor(Theme.taupeGrey)
                                
                                Slider(value: Binding(get: {
                                    scale
                                }, set: { newValue in
                                    scale = newValue
                                    lastScale = newValue
                                }), in: 1.0...5.0)
                                .tint(Theme.accent)
                                
                                Image(systemName: "plus.magnifyingglass")
                                    .foregroundColor(Theme.taupeGrey)
                            }
                            .padding(.horizontal, 32)
                        }
                        .padding(.top, 24)"""

content = content.replace(old_preview, new_preview)

with open("PumpCheck.swiftpm/Onboarding/LogProgressModal.swift", "w") as f:
    f.write(content)

