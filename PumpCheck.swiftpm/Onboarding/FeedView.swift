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
    var replies: [PostComment] = []
}

import FirebaseFirestore
import FirebaseAuth

struct FeedPost: Identifiable {
    let id: String
    let userId: String
    let username: String
    var profilePictureBase64: String?
    var photoBase64: String
    var photos: [String] = [] // New array for multiple photos
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
    @State private var navToProfileId: String? = nil
    @State private var navToProfileName: String? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach($posts) { $post in
                            FeedPostView(
                                post: $post, 
                                selectedPostId: $selectedPostId,
                                onNavigateToProfile: { uid, uname in
                                    navToProfileId = uid
                                    navToProfileName = uname
                                }
                            )
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
                
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.pitchBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(isPresented: Binding(
                get: { navToProfileId != nil },
                set: { if !$0 { navToProfileId = nil; navToProfileName = nil } }
            )) {
                if let uid = navToProfileId, let uname = navToProfileName {
                    PublicProfileView(userId: uid, username: uname)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            let db = Firestore.firestore()
                            if let snap = try? await db.collection("posts").getDocuments() {
                                for doc in snap.documents {
                                    try? await db.collection("posts").document(doc.documentID).delete()
                                }
                            }
                            await fetchPosts()
                        }
                    }) {
                        Text("Clear All")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreatePost = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .toolbar(selectedPostId == nil ? .visible : .hidden, for: .navigationBar)
        }
        .task {
            await fetchPosts()
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostModalView(viewModel: viewModel, isPresented: $showCreatePost, onPostCreated: {
                Task {
                    await fetchPosts()
                }
            })
        }
        .fullScreenCover(isPresented: Binding(
            get: { selectedPostId != nil },
            set: { if !$0 { selectedPostId = nil } }
        )) {
            if let selectedId = selectedPostId, let index = posts.firstIndex(where: { $0.id == selectedId }) {
                CommentModalView(
                    viewModel: viewModel, 
                    post: $posts[index], 
                    onClose: {
                        selectedPostId = nil
                    },
                    onNavigateToProfile: { uid, uname in
                        selectedPostId = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            navToProfileId = uid
                            navToProfileName = uname
                        }
                    }
                )
            }
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
                let pfp = data["profilePictureBase64"] as? String
                let photoBase64 = data["photoBase64"] as? String ?? ""
                let photos = data["photos"] as? [String] ?? (photoBase64.isEmpty ? [] : [photoBase64])
                let caption = data["caption"] as? String ?? ""
                let kudos = data["kudos"] as? Int ?? 0
                let kudoedBy = data["kudoedBy"] as? [String] ?? []
                let currentUid = Auth.auth().currentUser?.uid ?? ""
                let isKudoed = kudoedBy.contains(currentUid)
                let ts = data["date"] as? Timestamp
                let date = ts?.dateValue() ?? Date()
                
                var parsedComments: [PostComment] = []
                if let rawComments = data["comments"] as? [[String: Any]] {
                    for c in rawComments {
                        let cId = c["id"] as? String ?? UUID().uuidString
                        let cUserId = c["userId"] as? String ?? ""
                        let cUsername = c["username"] as? String ?? ""
                        let cPhoto = c["photoBase64"] as? String ?? ""
                        let cText = c["text"] as? String ?? ""
                        let cLikes = c["likesCount"] as? Int ?? 0
                        var cReplies: [PostComment] = []
                        if let rawReplies = c["replies"] as? [[String: Any]] {
                            for r in rawReplies {
                                let rId = r["id"] as? String ?? UUID().uuidString
                                let rUserId = r["userId"] as? String ?? ""
                                let rUsername = r["username"] as? String ?? ""
                                let rPhoto = r["photoBase64"] as? String ?? ""
                                let rText = r["text"] as? String ?? ""
                                let rLikes = r["likesCount"] as? Int ?? 0
                                cReplies.append(PostComment(id: rId, userId: rUserId, username: rUsername, photoBase64: rPhoto, text: rText, isLiked: false, likesCount: rLikes, replies: []))
                            }
                        }
                        parsedComments.append(PostComment(id: cId, userId: cUserId, username: cUsername, photoBase64: cPhoto, text: cText, isLiked: false, likesCount: cLikes, replies: cReplies))
                    }
                }
                
                var post = FeedPost(id: id, userId: userId, username: username, profilePictureBase64: pfp, photoBase64: photoBase64, photos: photos, kudos: kudos, isKudoed: isKudoed, caption: caption, date: date)
                post.comments = parsedComments
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
    var onNavigateToProfile: (String, String) -> Void
    
    @State private var profileImageData: Data? = nil
    @State private var sliderValue: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // Header
            HStack {
                Button { onNavigateToProfile(post.userId, post.username) } label: {
                    HStack(spacing: 12) {
                        if let data = profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else if let pfp = post.profilePictureBase64, !pfp.isEmpty, let uiImage = ImageCache.decode(base64: pfp) {
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
                                    Text(String(post.username.prefix(1).uppercased()))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Theme.textPrimary)
                                )
                        }
                        
                        Text(post.username)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                    }
                }
                .padding(.vertical, 8)
                Spacer()
                Text(post.date, style: .time)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 16)

            
            // Image area
            if post.photos.count > 1 {
                VStack(spacing: 0) {
                    let currentIndex = Int(round(sliderValue))
                    if currentIndex >= 0 && currentIndex < post.photos.count,
                       let uiImage = ImageCache.decode(base64: post.photos[currentIndex]) {
                        
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
                            .overlay(
                                Text("Photo error").foregroundColor(Theme.taupeGrey)
                            )
                    }
                    
                    // The Flicker Slider
                    VStack(spacing: 4) {
                        Slider(value: $sliderValue, in: 0...Double(post.photos.count - 1), onEditingChanged: { editing in
                            if !editing {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    sliderValue = round(sliderValue)
                                }
                            }
                        })
                            .tint(Theme.accent)
                        
                        HStack {
                            Text("Earliest")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.taupeGrey)
                            Spacer()
                            Text("Latest")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Theme.taupeGrey)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
            } else if let firstPhoto = post.photos.first, let uiImage = ImageCache.decode(base64: firstPhoto) {
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
                    Button { onNavigateToProfile(post.userId, post.username) } label: {
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
        
        let db = Firestore.firestore()
        let uid = Auth.auth().currentUser?.uid ?? ""
        let postId = post.id
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if post.isKudoed {
                post.kudos -= 1
                post.isKudoed = false
                if !uid.isEmpty {
                    db.collection("posts").document(postId).updateData([
                        "kudos": FieldValue.increment(Int64(-1)),
                        "kudoedBy": FieldValue.arrayRemove([uid])
                    ])
                }
            } else {
                post.kudos += 1
                post.isKudoed = true
                if !uid.isEmpty {
                    db.collection("posts").document(postId).updateData([
                        "kudos": FieldValue.increment(Int64(1)),
                        "kudoedBy": FieldValue.arrayUnion([uid])
                    ])
                }
            }
        }
    }
}
