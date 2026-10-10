import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseAuth

enum PostMode: String, CaseIterable {
    case single = "Single"
    case progress = "Progress"
}

struct CreatePostModalView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var isPresented: Bool
    var onPostCreated: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var postMode: PostMode = .single
    
    // Single Mode State
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    // Progress Mode State
    @State private var selectedProgressEntries: [ProgressEntry] = []
    @State private var showCalendarPicker = false
    
    @State private var caption: String = ""
    @State private var isUploading = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.pitchBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Picker("Post Mode", selection: $postMode) {
                            ForEach(PostMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        ZStack(alignment: .top) {
                            if postMode == .single {
                                singleModeView
                                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
                            } else {
                                progressModeView
                                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                            }
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: postMode)
                        
                        // Caption
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Caption")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                            
                            TextField("Write a caption...", text: $caption, axis: .vertical)
                                .lineLimit(3...6)
                                .padding()
                                .background(Theme.cardBackground)
                                .cornerRadius(12)
                                .foregroundColor(Theme.textPrimary)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Theme.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createPost) {
                        if isUploading {
                            ProgressView()
                                .tint(Theme.accent)
                        } else {
                            Text("Post")
                                .bold()
                                .foregroundColor(isPostValid ? Theme.accent : Theme.textSecondary)
                        }
                    }
                    .disabled(!isPostValid || isUploading)
                }
            }
            .sheet(isPresented: $showCalendarPicker) {
                CalendarPhotoPickerView(allEntries: viewModel.progressEntries, selectedEntries: $selectedProgressEntries)
            }
            .alert("Upload Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var singleModeView: some View {
        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
            if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(16)
                    .padding(.horizontal)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Theme.cardBackground)
                        .frame(height: 300)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.taupeGrey)
                        Text("Select Photo")
                            .font(.headline)
                            .foregroundColor(Theme.taupeGrey)
                    }
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    // compress
                    if let uiImg = UIImage(data: data), let compressed = uiImg.jpegData(compressionQuality: 0.1) {
                        selectedImageData = compressed
                    }
                }
            }
        }
    }
    
    private var progressModeView: some View {
        VStack(spacing: 16) {
            if selectedProgressEntries.isEmpty {
                Button { showCalendarPicker = true } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                            .foregroundColor(Theme.taupeGrey.opacity(0.5))
                            .frame(height: 150)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.accent)
                            Text("Add Photos from Calendar")
                                .font(.headline)
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        let postCrop = ProgressCoverage.commonCrop(selectedProgressEntries.map(\.coverage))
                        ForEach(selectedProgressEntries) { entry in
                            if let data = Data(base64Encoded: entry.photoBase64), let original = UIImage(data: data) {
                                // Preview exactly what gets posted: the shared crop without black borders
                                let uiImg = ProgressCoverage.cropped(original, to: postCrop)
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: uiImg)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 150, height: 200)
                                        .clipped()
                                        .cornerRadius(12)
                                    
                                    // Remove button
                                    Button {
                                        withAnimation {
                                            selectedProgressEntries.removeAll(where: { $0.id == entry.id })
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                            .background(Circle().fill(Theme.paleSky))
                                            .padding(6)
                                    }
                                }
                            }
                        }
                        
                        Button { showCalendarPicker = true } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.cardBackground)
                                    .frame(width: 150, height: 200)
                                Image(systemName: "plus")
                                    .font(.title)
                                    .foregroundColor(Theme.accent)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var isPostValid: Bool {
        if postMode == .single {
            return selectedImageData != nil
        } else {
            return !selectedProgressEntries.isEmpty
        }
    }
    
    private func createPost() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isUploading = true
        print("CREATE POST STARTED")
        
        let db = Firestore.firestore()
        let postId = UUID().uuidString
        
        // Run image processing in background to not block UI
        Task {
            var processedPhotos: [String] = []
            
            if postMode == .single {
                if let selectedImageData {
                    processedPhotos.append(selectedImageData.base64EncodedString())
                }
            } else {
                let sorted = selectedProgressEntries.sorted(by: { $0.date < $1.date })
                // Same shared crop as the progress slider, so the posted photos line up without black borders
                let postCrop = ProgressCoverage.commonCrop(sorted.map(\.coverage))
                for entry in sorted {
                    if let data = Data(base64Encoded: entry.photoBase64),
                       let original = UIImage(data: data) {
                        let uiImg = ProgressCoverage.cropped(original, to: postCrop)
                        let resized = uiImg.size.width > 600 ? uiImg.resized(toWidth: 600) ?? uiImg : uiImg
                        if let compressed = resized.jpegData(compressionQuality: 0.3) {
                            processedPhotos.append(compressed.base64EncodedString())
                        } else {
                            processedPhotos.append(entry.photoBase64)
                        }
                    }
                }
            }
            
            let photos = processedPhotos
            
            var pfpStr = ""
            if let data = viewModel.profileImageData, let uiImage = UIImage(data: data) {
                let targetSize = CGSize(width: 100, height: 100)
                UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
                uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
                let resized = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                if let compressedData = resized?.jpegData(compressionQuality: 0.2) {
                    pfpStr = compressedData.base64EncodedString()
                }
            }
            let postData: [String: Any] = [
                "id": postId,
                "userId": uid,
                "username": viewModel.username,
                "profilePictureBase64": pfpStr,
                "photoBase64": photos.first ?? "",
                "photos": photos,
                "kudos": 0,
                "caption": caption,
                "date": FieldValue.serverTimestamp()
            ]
            
            print("Writing to Firestore with \(photos.count) photos...")
            
            do {
                try await db.collection("posts").document(postId).setData(postData)
                print("Write successful!")
                await MainActor.run {
                    isUploading = false
                    onPostCreated()
                    isPresented = false
                    dismiss()
                }
            } catch {
                print("Firebase Error: \(error.localizedDescription)")
                await MainActor.run {
                    isUploading = false
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
    }
}

struct CalendarPhotoPickerView: View {
    let allEntries: [ProgressEntry]
    @Binding var selectedEntries: [ProgressEntry]
    @Environment(\.dismiss) var dismiss
    
    // Sort entries so latest is at the top in the picker
    private var sortedEntries: [ProgressEntry] {
        allEntries.sorted(by: { $0.date > $1.date })
    }
    
    let columns = [GridItem(.adaptive(minimum: 100), spacing: 2)]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.pitchBlack.ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(sortedEntries) { entry in
                            if !entry.photoBase64.isEmpty {
                                let isSelected = selectedEntries.contains(where: { $0.id == entry.id })
                                
                                ZStack(alignment: .topTrailing) {
                                    if let data = Data(base64Encoded: entry.photoBase64), let uiImg = UIImage(data: data) {
                                        Image(uiImage: uiImg)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(minWidth: 100, maxWidth: .infinity, minHeight: 100, maxHeight: .infinity)
                                            .aspectRatio(1, contentMode: .fit)
                                            .clipped()
                                    } else {
                                        Rectangle().fill(Theme.cardBackground).aspectRatio(1, contentMode: .fit)
                                    }
                                    
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Theme.accent)
                                            .background(Circle().fill(Theme.pitchBlack.opacity(0.6)))
                                            .padding(6)
                                    }
                                }
                                .onTapGesture {
                                    if isSelected {
                                        selectedEntries.removeAll(where: { $0.id == entry.id })
                                    } else {
                                        selectedEntries.append(entry)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .bold()
                        .foregroundColor(Theme.accent)
                }
            }
        }
    }
}


extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
