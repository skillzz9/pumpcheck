import re

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "r") as f:
    content = f.read()

target = """    private func createPost() {
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
            // Aggressively re-compress to ensure multiple photos fit in 1MB Firestore limit
            for entry in sorted {
                if let data = Data(base64Encoded: entry.photoBase64),
                   let uiImg = UIImage(data: data) {
                    
                    let resized = uiImg.size.width > 600 ? uiImg.resized(toWidth: 600) ?? uiImg : uiImg
                    if let compressed = resized.jpegData(compressionQuality: 0.3) {
                        photos.append(compressed.base64EncodedString())
                    } else {
                        photos.append(entry.photoBase64)
                    }
                }
            }
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
            if let error = error {
                print("Firebase Error: \\(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            } else {
                onPostCreated()
                dismiss()
            }
        }
    }"""

replacement = """    private func createPost() {
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
                for entry in sorted {
                    if let data = Data(base64Encoded: entry.photoBase64),
                       let uiImg = UIImage(data: data) {
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
            
            let postData: [String: Any] = [
                "id": postId,
                "userId": uid,
                "username": viewModel.username,
                "photoBase64": photos.first ?? "",
                "photos": photos,
                "kudos": 0,
                "caption": caption,
                "date": FieldValue.serverTimestamp()
            ]
            
            print("Writing to Firestore with \\(photos.count) photos...")
            
            do {
                try await db.collection("posts").document(postId).setData(postData)
                print("Write successful!")
                await MainActor.run {
                    isUploading = false
                    onPostCreated()
                    dismiss()
                }
            } catch {
                print("Firebase Error: \\(error.localizedDescription)")
                await MainActor.run {
                    isUploading = false
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
    }"""

if target in content:
    content = content.replace(target, replacement)
    with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "w") as f:
        f.write(content)
    print("Patched CreatePostModalView with async processing!")
else:
    print("Target not found!")
