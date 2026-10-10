import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CommentModalView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var post: FeedPost
    var onClose: () -> Void
    var onNavigateToProfile: (String, String) -> Void
    @State private var commentText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var replyingToId: String? = nil
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false
    @State private var sliderValue: Double = 0
    @AppStorage(ProgressSliderMode.storageKey) private var sliderMode: ProgressSliderMode = .flicker
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                        .padding(16)
                        .contentShape(Rectangle())
                }
                .padding(.leading, -16)
                
                Spacer()
                
                Text("Comments")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.left")
                    .foregroundColor(.clear)
            }
            .padding()
            .background(Theme.pitchBlack)
            
            // Image (1/3 of screen): the same progress slider as the feed when the post has several photos
            if post.photos.count > 1 {
                VStack(spacing: 0) {
                    ProgressPhotoStack(photos: post.photos, sliderValue: sliderValue, mode: sliderMode)
                        .frame(height: UIScreen.main.bounds.height / 3)
                        .frame(maxWidth: .infinity)
                        .background(Theme.pitchBlack)
                        .clipped()
                        .overlay(alignment: .topTrailing) {
                            ProgressSliderModeToggle(mode: $sliderMode)
                        }

                    VStack(spacing: 4) {
                        Slider(value: $sliderValue, in: 0...Double(post.photos.count - 1), onEditingChanged: { editing in
                            if !editing && sliderMode == .flicker {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    sliderValue = round(sliderValue)
                                }
                            }
                        })
                        .tint(Theme.accent)

                        HStack {
                            Text("Earliest")
                            Spacer()
                            Text("Latest")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.taupeGrey)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                }
                .background(Theme.pitchBlack)
                .task(id: post.photos.count) {
                    await DemoMode.autoSlide(photoCount: post.photos.count) { sliderValue = $0 }
                }
            } else {
            GeometryReader { geo in
                if let uiImage = ImageCache.decode(base64: post.photoBase64) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .background(Theme.pitchBlack)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Theme.cardBackground)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.taupeGrey.opacity(0.5))
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            }
            .frame(height: UIScreen.main.bounds.height / 3)
            }
            
            // Comments area
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if post.comments.isEmpty {
                        Text("No comments yet.")
                            .foregroundColor(Theme.textSecondary)
                            .padding(.top, 40)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach($post.comments) { $comment in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {
                                // Profile picture: the commenter's current one, not the copy saved with the comment
                                UserAvatar(userId: comment.userId, username: comment.username, fallbackBase64: comment.photoBase64, size: 36)
                                
                                // Username and comment text
                                VStack(alignment: .leading, spacing: 4) {
                                    // Username on its own line so the comment wraps across the full width
                                    VStack(alignment: .leading, spacing: 2) {
                                        Button { onNavigateToProfile(comment.userId, comment.username) } label: {
                                            Text(comment.username)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Theme.textPrimary)
                                        }
                                        Text(comment.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(Theme.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        if comment.likesCount > 0 {
                                            Text("\(comment.likesCount.compactCount) likes")
                                                .font(.system(size: 12))
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                        Button {
                                            replyingToId = comment.id
                                            commentText = "@\(comment.username) "
                                            isInputFocused = true
                                        } label: {
                                            Text("Reply")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Theme.textSecondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                // Like button
                                Button {
                                    withAnimation {
                                        if comment.isLiked {
                                            comment.likesCount -= 1
                                        } else {
                                            comment.likesCount += 1
                                        }
                                        comment.isLiked.toggle()
                                    }
                                } label: {
                                    Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                                        .font(.system(size: 14))
                                        .foregroundColor(comment.isLiked ? Theme.accent : Theme.textSecondary)
                                }
                                .padding(.top, 2)
                            }
                            
                            if !comment.replies.isEmpty {
                                ForEach($comment.replies) { $reply in
                                    HStack(alignment: .top, spacing: 12) {
                                        UserAvatar(userId: reply.userId, username: reply.username, fallbackBase64: reply.photoBase64, size: 28)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Button { onNavigateToProfile(reply.userId, reply.username) } label: {
                                                Text(reply.username)
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundColor(Theme.textPrimary)
                                            }
                                            Text(reply.text)
                                                .font(.system(size: 13))
                                                .foregroundColor(Theme.textPrimary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Button {
                                            withAnimation {
                                                if reply.isLiked {
                                                    reply.likesCount -= 1
                                                } else {
                                                    reply.likesCount += 1
                                                }
                                                reply.isLiked.toggle()
                                            }
                                        } label: {
                                            Image(systemName: reply.isLiked ? "heart.fill" : "heart")
                                                .font(.system(size: 12))
                                                .foregroundColor(reply.isLiked ? Theme.accent : Theme.textSecondary)
                                        }
                                        .padding(.top, 2)
                                    }
                                    .padding(.leading, 48)
                                }
                            }
                        }
                        }
                    }
                }
                .padding()
            }
            .background(Theme.bgGradient)
            
            // Write a comment section
            HStack {
                TextField("Add a comment...", text: $commentText)
                    .textFieldStyle(PumpTextFieldStyle())
                    .focused($isInputFocused)
                
                Button {
                    var base64 = ""
                    if let data = viewModel.profileImageData, let uiImage = UIImage(data: data) {
                        let targetSize = CGSize(width: 80, height: 80)
                        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
                        uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
                        let resized = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        if let compressedData = resized?.jpegData(compressionQuality: 0.1) {
                            base64 = compressedData.base64EncodedString()
                        }
                    }
                    
                    let uid = Auth.auth().currentUser?.uid ?? ""
                    let newComment = PostComment(
                        id: UUID().uuidString,
                        userId: uid,
                        username: viewModel.username,
                        photoBase64: base64,
                        text: commentText,
                        isLiked: false,
                        likesCount: 0
                    )
                    
                    withAnimation {
                        if let repId = replyingToId, let idx = post.comments.firstIndex(where: { $0.id == repId }) {
                            post.comments[idx].replies.append(newComment)
                        } else {
                            post.comments.append(newComment)
                        }
                    }
                    
                    replyingToId = nil
                    commentText = ""
                    
                    let db = Firestore.firestore()
                    let dicts = post.comments.map { c -> [String: Any] in
                        var cDict: [String: Any] = [
                            "id": c.id, "userId": c.userId, "username": c.username,
                            "photoBase64": c.photoBase64, "text": c.text, "likesCount": c.likesCount
                        ]
                        let rDicts = c.replies.map { r -> [String: Any] in
                            ["id": r.id, "userId": r.userId, "username": r.username,
                             "photoBase64": r.photoBase64, "text": r.text, "likesCount": r.likesCount]
                        }
                        cDict["replies"] = rDicts
                        return cDict
                    }
                    db.collection("posts").document(post.id).setData(["comments": dicts], merge: true) { error in
                        if error != nil {
                            self.errorMessage = "Your comment couldn't be posted. Check your connection and try again."
                            self.showErrorAlert = true
                        }
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 24))
                        .foregroundColor(commentText.isEmpty ? Theme.taupeGrey : Theme.accent)
                }
                .disabled(commentText.isEmpty)
            }
            .padding()
            .background(Theme.pitchBlack)
            .padding(.bottom, 10) // Extra padding for safe area on newer iPhones if needed
        }
        .background(Theme.pitchBlack.ignoresSafeArea())
        .alert("Comment Not Posted", isPresented: $showErrorAlert, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { msg in
            Text(msg)
        }
    }
}
