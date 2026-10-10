import SwiftUI
import FirebaseFirestore

/// Current profile pictures by user ID, fetched once per session and shared by every avatar.
@MainActor
final class ProfilePhotoCache {
    static let shared = ProfilePhotoCache()

    private var photos: [String: UIImage] = [:]
    private var loading: [String: Task<UIImage?, Never>] = [:]

    func photo(for userId: String) async -> UIImage? {
        if let photo = photos[userId] { return photo }
        if let task = loading[userId] { return await task.value }

        let task = Task<UIImage?, Never> {
            let doc = try? await Firestore.firestore().collection("users").document(userId).getDocument()
            guard let base64 = doc?.data()?["photoBase64"] as? String else { return nil }
            return ImageCache.decode(base64: base64)
        }
        loading[userId] = task
        let photo = await task.value
        loading[userId] = nil
        if let photo { photos[userId] = photo }
        return photo
    }

    /// Called when the signed-in user changes their picture, so avatars update straight away.
    func set(_ photo: UIImage, for userId: String) {
        photos[userId] = photo
    }
}

/// A user's current profile picture in a circle. Falls back to the copy stored with the
/// post or comment, then to their initial.
struct UserAvatar: View {
    let userId: String
    let username: String
    var fallbackBase64: String = ""
    var size: CGFloat = 36

    @State private var photo: UIImage?

    var body: some View {
        Group {
            if let image = photo ?? (fallbackBase64.isEmpty ? nil : ImageCache.decode(base64: fallbackBase64)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(Theme.taupeGrey.opacity(0.5))
                    .overlay(
                        Text(String(username.prefix(1).uppercased()))
                            .font(.system(size: size * 0.4, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: userId) {
            guard !userId.isEmpty else { return }
            photo = await ProfilePhotoCache.shared.photo(for: userId)
        }
    }
}
