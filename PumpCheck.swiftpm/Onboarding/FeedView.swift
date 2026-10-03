import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PostComment: Identifiable {
    let id: String
    let userId: String
    let username: String
    let photoBase64: String
    let text: String
    var isLiked: Bool
    var likesCount: Int
}

import FirebaseFirestore
import FirebaseAuth

struct FeedPost: Identifiable {
    let id: String
    let userId: String
    let username: String
    var photoBase64: String
    var kudos: Int
    var isKudoed: Bool
    var caption: String
    var date: Date
    var comments: [PostComment] = []
}

struct FeedView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    @State private var posts: [FeedPost] = []
    @State private var isLoading = true
    @State private var showCreatePost = false
    
    @State private var selectedPostId: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach($posts) { $post in
                            FeedPostView(post: $post, selectedPostId: $selectedPostId)
                        }
                    }
                    .padding(.vertical)
                }
                
                if let selectedId = selectedPostId, let index = posts.firstIndex(where: { $0.id == selectedId }) {
                    CommentModalView(viewModel: viewModel, post: $posts[index], isPresented: Binding(
                        get: { selectedPostId != nil },
                        set: { if !$0 { selectedPostId = nil } }
                    ))
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.pitchBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreatePost = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Theme.accent)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .task {
            await fetchPosts()
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostModalView(isPresented: $showCreatePost, viewModel: viewModel, onPostCreated: {
                Task {
                    await fetchPosts()
                }
            })
        }
    }
    
    private func fetchPosts() async {
        isLoading = true
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("posts").order(by: "date", descending: true).getDocuments()
            var fetchedPosts: [FeedPost] = []
            
            for doc in snapshot.documents {
                let data = doc.data()
                let id = data["id"] as? String ?? doc.documentID
                let userId = data["userId"] as? String ?? ""
                let username = data["username"] as? String ?? "Unknown"
                let photoBase64 = data["photoBase64"] as? String ?? ""
                let caption = data["caption"] as? String ?? ""
                let kudos = data["kudos"] as? Int ?? 0
                let ts = data["date"] as? Timestamp
                let date = ts?.dateValue() ?? Date()
                
                let post = FeedPost(id: id, userId: userId, username: username, photoBase64: photoBase64, kudos: kudos, isKudoed: false, caption: caption, date: date)
                fetchedPosts.append(post)
            }
            
            await MainActor.run {
                self.posts = fetchedPosts
                self.isLoading = false
            }
        } catch {
            print("Error fetching posts: \(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct FeedPostView: View {
    @Binding var post: FeedPost
    @Binding var selectedPostId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // Header
            HStack {
                NavigationLink(destination: PublicProfileView(userId: post.userId, username: post.username)) {
                    Text(post.username)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                Text(post.date, style: .time)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 16)
            
            // Image area
            if let data = Data(base64Encoded: post.photoBase64), let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.0, contentMode: .fit)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Theme.cardBackground)
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(Theme.taupeGrey.opacity(0.5))
                    }
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                // Kudo Button
                Button {
                    toggleKudo()
                } label: {
                    Image(systemName: post.isKudoed ? "heart.fill" : "heart")
                        .font(.system(size: 24))
                        .foregroundColor(post.isKudoed ? Theme.accent : Theme.textPrimary)
                }
                
                // Comment Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedPostId = post.id
                    }
                } label: {
                    Image(systemName: "message")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            
            // Kudo count
            if post.kudos > 0 {
                Text("\(post.kudos) \(post.kudos == 1 ? "kudo" : "kudos")")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 12)
            }
            
            // Caption
            if !post.caption.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    NavigationLink(destination: PublicProfileView(userId: post.userId, username: post.username)) {
                        Text(post.username).bold()
                            .foregroundColor(Theme.textPrimary)
                    }
                    Text(post.caption)
                        .foregroundColor(Theme.textPrimary)
                }
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, 12)
            }
        }
    }
    
    private func toggleKudo() {
        #if canImport(UIKit)
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        #endif
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if post.isKudoed {
                post.kudos -= 1
            } else {
                post.kudos += 1
            }
            post.isKudoed.toggle()
        }
    }
}
