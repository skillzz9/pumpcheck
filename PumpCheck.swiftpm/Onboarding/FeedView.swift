import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct PostComment: Identifiable {
    let id: String
    let username: String
    let photoBase64: String
    let text: String
    var isLiked: Bool
    var likesCount: Int
}

struct FeedPost: Identifiable {
    let id: String
    let username: String
    let imageName: String // Mock for now
    var kudos: Int
    var isKudoed: Bool
    var caption: String
    var comments: [PostComment] = []
}

struct FeedView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    @State private var posts: [FeedPost] = [
        FeedPost(id: "1", username: "alex_fitness", imageName: "dummy1", kudos: 12, isKudoed: false, caption: "Crushed the morning workout! 💪", comments: [
            PostComment(id: "c1", username: "gym_bro", photoBase64: "", text: "Looking huge man!", isLiked: false, likesCount: 2)
        ]),
        FeedPost(id: "2", username: "sarah_lifts", imageName: "dummy2", kudos: 45, isKudoed: true, caption: "Leg day is the best day. 🦵", comments: []),
        FeedPost(id: "3", username: "mike_pump", imageName: "dummy3", kudos: 0, isKudoed: false, caption: "Rest day vibes.", comments: [])
    ]
    
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
        }
    }
}

struct FeedPostView: View {
    @Binding var post: FeedPost
    @Binding var selectedPostId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image area (Mocked as a rectangle with a photo icon)
            Rectangle()
                .fill(Theme.cardBackground)
                .aspectRatio(1.0, contentMode: .fit)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.taupeGrey.opacity(0.5))
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
