import SwiftUI

struct CommentModalView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var post: FeedPost
    @Binding var isPresented: Bool
    @State private var commentText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                }
                
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
                            HStack(alignment: .top, spacing: 12) {
                                // Profile picture
                                Group {
                                    if !comment.photoBase64.isEmpty, let imgData = Data(base64Encoded: comment.photoBase64), let uiImage = UIImage(data: imgData) {
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
                                    Text(comment.username)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                    + Text(" ")
                                    + Text(comment.text)
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.textPrimary)
                                    
                                    // Reply / likes count (optional instagram style)
                                    if comment.likesCount > 0 {
                                        Text("\(comment.likesCount) likes")
                                            .font(.system(size: 12))
                                            .foregroundColor(Theme.textSecondary)
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
                
                Button {
                    let base64 = viewModel.profileImageData?.base64EncodedString() ?? ""
                    let newComment = PostComment(
                        id: UUID().uuidString,
                        username: viewModel.username,
                        photoBase64: base64,
                        text: commentText,
                        isLiked: false,
                        likesCount: 0
                    )
                    withAnimation {
                        post.comments.append(newComment)
                    }
                    commentText = ""
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
    }
}
