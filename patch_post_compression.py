import re

with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "r") as f:
    content = f.read()

target = """        var photos: [String] = []
        if postMode == .single {
            if let selectedImageData {
                photos.append(selectedImageData.base64EncodedString())
            }
        } else {
            // Sort by date (earliest to latest)
            let sorted = selectedProgressEntries.sorted(by: { $0.date < $1.date })
            photos = sorted.map { $0.photoBase64 }.filter { !$0.isEmpty }
        }"""

replacement = """        var photos: [String] = []
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
        }"""

content = content.replace(target, replacement)

extension = """

extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
"""

if "func resized(toWidth" not in content:
    content += extension

# Also log the error to the console and add an alert state so the user can see it if it fails again
target_error = """        db.collection("posts").document(postId).setData(postData) { error in
            isUploading = false
            if error == nil {
                onPostCreated()
                dismiss()
            }
        }"""

replacement_error = """        db.collection("posts").document(postId).setData(postData) { error in
            isUploading = false
            if let error = error {
                print("Firebase Error: \\(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            } else {
                onPostCreated()
                dismiss()
            }
        }"""

content = content.replace(target_error, replacement_error)

state_target = """    @State private var caption: String = ""
    @State private var isUploading = false"""

state_replacement = """    @State private var caption: String = ""
    @State private var isUploading = false
    @State private var showErrorAlert = false
    @State private var errorMessage = \"\""""

if "showErrorAlert" not in content:
    content = content.replace(state_target, state_replacement)
    
alert_target = """            .sheet(isPresented: $showCalendarPicker) {
                CalendarPhotoPickerView(allEntries: viewModel.progressEntries, selectedEntries: $selectedProgressEntries)
            }
        }
    }"""

alert_replacement = """            .sheet(isPresented: $showCalendarPicker) {
                CalendarPhotoPickerView(allEntries: viewModel.progressEntries, selectedEntries: $selectedProgressEntries)
            }
            .alert("Upload Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }"""
content = content.replace(alert_target, alert_replacement)


with open("PumpCheck.swiftpm/Onboarding/CreatePostModalView.swift", "w") as f:
    f.write(content)

print("Patched CreatePostModalView successfully!")
