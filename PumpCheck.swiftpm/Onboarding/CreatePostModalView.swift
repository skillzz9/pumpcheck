import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

struct CreatePostModalView: View {
    @Binding var isPresented: Bool
    var viewModel: OnboardingViewModel
    var onPostCreated: () -> Void
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var caption: String = ""
    @State private var isPosting = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image Picker Area
                        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal)
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Theme.cardBackground)
                                        .frame(height: 300)
                                    
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(Theme.accent)
                                        Text("Tap to select photo")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(Theme.textSecondary)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                        
                        // Caption Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Caption")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.textPrimary)
                            
                            TextField("Write something...", text: $caption, axis: .vertical)
                                .textFieldStyle(PumpTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        // Submit Button
                        Button(action: createPost) {
                            if isPosting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.pitchBlack))
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity)
                                    .background(Theme.accent)
                                    .cornerRadius(16)
                            } else {
                                Text("Post")
                                    .pumpButtonStyle(isPrimary: selectedImageData != nil)
                            }
                        }
                        .disabled(selectedImageData == nil || isPosting)
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 24)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(Theme.textPrimary)
                }
            }
        }
    }
    
    private func createPost() {
        guard let data = selectedImageData, let uiImage = UIImage(data: data) else { return }
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        isPosting = true
        
        Task {
            var photoBase64 = ""
            if let compressedData = uiImage.jpegData(compressionQuality: 0.1) {
                photoBase64 = compressedData.base64EncodedString()
            }
            
            let db = Firestore.firestore()
            let postId = UUID().uuidString
            
            let postData: [String: Any] = [
                "id": postId,
                "userId": uid,
                "username": viewModel.username,
                "photoBase64": photoBase64,
                "caption": caption,
                "kudos": 0,
                "date": FieldValue.serverTimestamp()
            ]
            
            do {
                try await db.collection("posts").document(postId).setData(postData)
                await MainActor.run {
                    isPosting = false
                    isPresented = false
                    onPostCreated()
                }
            } catch {
                print("Error creating post: \(error.localizedDescription)")
                await MainActor.run {
                    isPosting = false
                    errorMessage = "Firebase Error: \(error.localizedDescription). Check your Firestore Security Rules!"
                }
            }
        }
    }
}
