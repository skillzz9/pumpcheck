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
    @Environment(\\.dismiss) var dismiss
    
    @State private var postMode: PostMode = .single
    
    // Single Mode State
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    
    // Progress Mode State
    @State private var selectedProgressEntries: [ProgressEntry] = []
    @State private var showCalendarPicker = false
    
    @State private var caption: String = ""
    @State private var isUploading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.pitchBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Picker("Post Mode", selection: $postMode) {
                            ForEach(PostMode.allCases, id: \\.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 16)
                        
                        if postMode == .single {
                            singleModeView
                        } else {
                            progressModeView
                        }
                        
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
                        ForEach(selectedProgressEntries) { entry in
                            if let data = Data(base64Encoded: entry.photoBase64), let uiImg = UIImage(data: data) {
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
                                            .background(Circle().fill(Color.white))
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
        
        let db = Firestore.firestore()
        let postId = UUID().uuidString
        
        var photos: [String] = []
        if postMode == .single {
            if let selectedImageData {
                photos.append(selectedImageData.base64EncodedString())
            }
        } else {
            // Sort by date (earliest to latest)
            let sorted = selectedProgressEntries.sorted(by: { $0.date < $1.date })
            photos = sorted.map { $0.photoBase64 }.filter { !$0.isEmpty }
        }
        
        let postData: [String: Any] = [
            "id": postId,
            "userId": uid,
            "username": viewModel.username,
            "photoBase64": photos.first ?? "", // fallback
            "photos": photos,
            "kudos": 0,
            "caption": caption,
            "date": FieldValue.serverTimestamp()
        ]
        
        db.collection("posts").document(postId).setData(postData) { error in
            isUploading = false
            if error == nil {
                dismiss()
            }
        }
    }
}

struct CalendarPhotoPickerView: View {
    let allEntries: [ProgressEntry]
    @Binding var selectedEntries: [ProgressEntry]
    @Environment(\\.dismiss) var dismiss
    
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
                                            .background(Circle().fill(Color.black.opacity(0.6)))
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
