import SwiftUI

struct LogProgressModal: View {
    @Bindable var viewModel: OnboardingViewModel
    let uiImage: UIImage
    var initialDate: Date
    var onSave: () -> Void
    var onCancel: () -> Void
    
    @State private var weight: String = ""
    @State private var newLifts: [LiftRecord] = []
    @State private var customDate: Date = Date()
    
    // Image Cropper State
    @State private var showCropModal = false
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var cropSize: CGSize = .zero

    var weightPercentChange: Double? {
        let cleanOld = viewModel.weight.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNew = weight.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        guard let oldW = Double(cleanOld),
              let newW = Double(cleanNew),
              oldW > 0 else { return nil }
        return ((newW - oldW) / oldW) * 100.0
    }

    var previousImage: UIImage? {
        let sortedEntries = viewModel.progressEntries.sorted(by: { $0.date < $1.date })
        if let lastEntry = sortedEntries.last {
            return ImageCache.decode(base64: lastEntry.photoBase64)
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image Preview
                        Button {
                            showCropModal = true
                        } label: {
                            ZStack {
                                Theme.pitchBlack
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .offset(
                                        x: offset.width * (cropSize.width > 0 ? 150.0 / cropSize.width : 1.0),
                                        y: offset.height * (cropSize.height > 0 ? (150.0 * (16.0 / 9.0)) / cropSize.height : 1.0)
                                    )
                                    .scaleEffect(scale)
                            }
                            .frame(width: 150, height: 150 * (16.0 / 9.0))
                            .clipped()
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.accent, lineWidth: 2))
                            .shadow(color: Theme.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                            .overlay(
                                VStack {
                                    Image(systemName: "crop")
                                        .font(.system(size: 24))
                                    Text("Crop")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(8)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 24)
                        
                        // Optional Weight
                        VStack(spacing: 8) {
                            HStack {
                                Text("Current Weight")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textPrimary)
                                
                                Spacer()
                                
                                if !viewModel.weight.isEmpty {
                                    Text(viewModel.weight)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(Theme.textPrimary)
                                    
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(Theme.accent)
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.horizontal, 4)
                                }
                                
                                TextField("New", text: $weight)
                                    .keyboardType(.decimalPad)
                                    .padding(12)
                                    .frame(width: 80)
                                    .background(Theme.textBoxBlue)
                                    .cornerRadius(12)
                                    .foregroundColor(Theme.textPrimary)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1))
                                
                                Text(viewModel.isWeightKg ? "kg" : "lbs")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.textSecondary)
                                    .padding(.leading, 4)
                            }
                            
                            if let inc = weightPercentChange {
                                HStack {
                                    Image(systemName: inc >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    Text(String(format: "%.1f%% %@", abs(inc), inc >= 0 ? "increase" : "decrease"))
                                }
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(inc >= 0 ? .green : .red)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        
                        // Lifts
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Update Lifts")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                                .padding(.horizontal, 24)
                            
                            ForEach($newLifts) { $lift in
                                LiftUpdateRow(lift: $lift, oldLifts: viewModel.proudestLifts)
                            }
                            
                            Button(action: {
                                newLifts.append(LiftRecord(name: "", weight: 0, reps: 0))
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Another Lift")
                                }
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.accent)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Theme.textBoxBlue)
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Custom Date Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                            
                            DatePicker("Select Date", selection: $customDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .colorScheme(.dark)
                                .labelsHidden()
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Log Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancel() }
                        .foregroundColor(Theme.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveProgress() }
                        .fontWeight(.bold)
                        .foregroundColor(Theme.accent)
                }
            }
            .onAppear {
                customDate = initialDate
                // Initialize with established lifts
                newLifts = viewModel.proudestLifts
                // If they have no established lifts, start with one empty one
                if newLifts.isEmpty {
                    newLifts.append(LiftRecord(name: "", weight: 0, reps: 0))
                }
            }
            .sheet(isPresented: $showCropModal) {
                ImageCropperModal(
                    uiImage: uiImage,
                    previousImage: previousImage,
                    scale: $scale,
                    offset: $offset,
                    lastScale: $lastScale,
                    lastOffset: $lastOffset,
                    cropSize: $cropSize
                ) {
                    showCropModal = false
                }
            }
        }
    }
    
    @MainActor
    func saveProgress() {
        // Render the image exactly as cropped, at a high resolution (1080 width, 9:16 aspect)
        let renderWidth: CGFloat = 1080
        let renderHeight: CGFloat = renderWidth * (16.0 / 9.0)
        
        let multX = cropSize.width > 0 ? renderWidth / cropSize.width : 1.0
        let multY = cropSize.height > 0 ? renderHeight / cropSize.height : 1.0
        
        let viewToRender = ZStack {
            Color.black
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .offset(x: offset.width * multX, y: offset.height * multY)
                .scaleEffect(scale)
        }
        .frame(width: renderWidth, height: renderHeight)
        .clipped()
        
        let renderer = ImageRenderer(content: viewToRender)
        renderer.scale = 1.0
        
        guard let finalImage = renderer.uiImage,
              let data = finalImage.jpegData(compressionQuality: 0.5) else { return }
              
        let base64 = data.base64EncodedString()
        
        let entry = ProgressEntry(
            id: UUID().uuidString,
            date: customDate,
            photoBase64: base64,
            weight: weight,
            lifts: newLifts
        )
        viewModel.saveProgressEntry(entry)
        
        // Update main profile stats
        var didUpdateStats = false
        if !weight.isEmpty && viewModel.weight != weight {
            viewModel.weight = weight
            didUpdateStats = true
        }
        for newLift in newLifts where newLift.weight > 0 && newLift.reps > 0 && !newLift.name.isEmpty {
            if let index = viewModel.proudestLifts.firstIndex(where: { $0.name.lowercased() == newLift.name.lowercased() }) {
                if viewModel.proudestLifts[index].weight != newLift.weight || viewModel.proudestLifts[index].reps != newLift.reps {
                    viewModel.proudestLifts[index] = newLift
                    didUpdateStats = true
                }
            } else {
                viewModel.proudestLifts.append(newLift)
                didUpdateStats = true
            }
        }
        
        if didUpdateStats {
            viewModel.syncProfileStatsToFirebase()
        }
        
        onSave()
    }
}

struct LiftUpdateRow: View {
    @Binding var lift: LiftRecord
    let oldLifts: [LiftRecord]
    
    // Create temporary string states for the TextFields to handle decimals properly
    @State private var weightStr: String = ""
    @State private var repsStr: String = ""
    
    var oldLift: LiftRecord? {
        oldLifts.first(where: { $0.name.lowercased() == lift.name.lowercased() })
    }
    
    var percentIncrease: Double? {
        guard let old = oldLift, old.weight > 0, old.reps > 0 else { return nil }
        guard lift.weight > 0, lift.reps > 0 else { return nil }
        
        // Use Epley formula for 1 Rep Max estimation: 1RM = W * (1 + R/30)
        let old1RM = old.weight * (1.0 + Double(old.reps) / 30.0)
        let new1RM = lift.weight * (1.0 + Double(lift.reps) / 30.0)
        
        return ((new1RM - old1RM) / old1RM) * 100.0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            TextField("Lift Name (e.g. Bench Press)", text: $lift.name)
                .textFieldStyle(PumpTextFieldStyle())
            
            VStack(spacing: 8) {
                // Weight Row
                HStack {
                    Text("Weight")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 60, alignment: .leading)
                    
                    Spacer()
                    
                    if let old = oldLift {
                        Text(old.weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", old.weight) : String(format: "%.1f", old.weight))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(Theme.accent)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 4)
                    }
                    
                    TextField("New", text: $weightStr)
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .frame(width: 80)
                        .background(Theme.textBoxBlue)
                        .cornerRadius(12)
                        .foregroundColor(Theme.textPrimary)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1))
                        .onChange(of: weightStr) { _, newValue in
                            lift.weight = Double(newValue) ?? 0
                        }
                }
                
                // Reps Row
                HStack {
                    Text("Reps")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 60, alignment: .leading)
                    
                    Spacer()
                    
                    if let old = oldLift {
                        Text("\(old.reps)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(Theme.accent)
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 4)
                    }
                    
                    TextField("New", text: $repsStr)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .frame(width: 80)
                        .background(Theme.textBoxBlue)
                        .cornerRadius(12)
                        .foregroundColor(Theme.textPrimary)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.taupeGrey.opacity(0.3), lineWidth: 1))
                        .onChange(of: repsStr) { _, newValue in
                            lift.reps = Int(newValue) ?? 0
                        }
                }
            }
            
            if let inc = percentIncrease {
                HStack {
                    Image(systemName: inc >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(String(format: "%.1f%% %@", abs(inc), inc >= 0 ? "increase" : "decrease"))
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(inc >= 0 ? .green : .red)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding()
        .background(Theme.cardBackground)
        .cornerRadius(16)
        .padding(.horizontal, 24)
        .onAppear {
            weightStr = lift.weight > 0 ? (lift.weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", lift.weight) : String(lift.weight)) : ""
            repsStr = lift.reps > 0 ? String(lift.reps) : ""
        }
    }
}

struct ImageCropperModal: View {
    var uiImage: UIImage
    var previousImage: UIImage?
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var lastScale: CGFloat
    @Binding var lastOffset: CGSize
    @Binding var cropSize: CGSize
    var onDone: () -> Void
    
    @State private var isBlending = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.pitchBlack.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    Color.clear
                        .aspectRatio(9.0 / 16.0, contentMode: .fit)
                        .overlay(
                            GeometryReader { geo in
                                ZStack {
                                    Theme.pitchBlack
                                    
                                    if isBlending, let prev = previousImage {
                                        Image(uiImage: prev)
                                            .resizable()
                                            .scaledToFill()
                                    }
                                    
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .offset(offset)
                                        .scaleEffect(scale)
                                        .opacity(isBlending ? 0.5 : 1.0)
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
                    
                    // Zoom Slider for Simulator
                    HStack {
                        Image(systemName: "minus.magnifyingglass").foregroundColor(Theme.taupeGrey)
                        Slider(value: Binding(get: { scale }, set: { val in scale = val; lastScale = val }), in: 1.0...5.0).tint(Theme.accent)
                        Image(systemName: "plus.magnifyingglass").foregroundColor(Theme.taupeGrey)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    
                    if previousImage != nil {
                        Button(action: {
                            isBlending.toggle()
                        }) {
                            Text(isBlending ? "Turn Blend Off" : "Blend with Previous")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isBlending ? Theme.accent : Theme.textBoxBlue)
                                .foregroundColor(isBlending ? Theme.pitchBlack : Theme.textPrimary)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 16)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Crop & Align")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.pitchBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDone()
                    }
                    .foregroundColor(Theme.accent)
                    .font(.system(size: 16, weight: .bold))
                }
            }
        }
    }
}
