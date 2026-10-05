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
            
            // Image (1/3 of screen)
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
                                // Profile picture
                                Group {
                                    if !comment.photoBase64.isEmpty, let uiImage = ImageCache.decode(base64: comment.photoBase64) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 36, height: 36)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Theme.taupeGrey.opacity(0.5))
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Text(String(comment.username.prefix(1).uppercased()))
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(Theme.textPrimary)
                                            )
                                    }
                                }
                                
                                // Username and comment text
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .top, spacing: 4) {
                                        Button { onNavigateToProfile(comment.userId, comment.username) } label: {
                                            Text(comment.username)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Theme.textPrimary)
                                        }
                                        Text(comment.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(Theme.textPrimary)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        if comment.likesCount > 0 {
                                            Text("\(comment.likesCount) likes")
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
                                
                                Spacer()
                                
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
                                        Group {
                                            if !reply.photoBase64.isEmpty, let uiImage = ImageCache.decode(base64: reply.photoBase64) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 28, height: 28)
                                                    .clipShape(Circle())
                                            } else {
                                                Circle()
                                                    .fill(Theme.taupeGrey.opacity(0.5))
                                                    .frame(width: 28, height: 28)
                                                    .overlay(
                                                        Text(String(reply.username.prefix(1).uppercased()))
                                                            .font(.system(size: 12, weight: .bold))
                                                            .foregroundColor(Theme.textPrimary)
                                                    )
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(alignment: .top, spacing: 4) {
                                                Button { onNavigateToProfile(reply.userId, reply.username) } label: {
                                                    Text(reply.username)
                                                        .font(.system(size: 13, weight: .bold))
                                                        .foregroundColor(Theme.textPrimary)
                                                }
                                                Text(reply.text)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(Theme.textPrimary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
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
                        if let error = error {
                            self.errorMessage = error.localizedDescription
                            self.showErrorAlert = true
                        } else {
                            // verify read
                            db.collection("posts").document(post.id).getDocument { doc, err in
                                if let err = err {
                                    self.errorMessage = "Saved, but failed to read back: \(err.localizedDescription)"
                                    self.showErrorAlert = true
                                }
                            }
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
        .alert("Firebase Error", isPresented: $showErrorAlert, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { msg in
            Text(msg)
        }
    }
}
