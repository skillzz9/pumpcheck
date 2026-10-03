import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct FeedPost: Identifiable {
    let id: String
    let username: String
    let imageName: String // Mock for now
    var kudos: Int
    var isKudoed: Bool
    var caption: String
}

struct FeedView: View {
    @State private var posts: [FeedPost] = [
        FeedPost(id: "1", username: "alex_fitness", imageName: "dummy1", kudos: 12, isKudoed: false, caption: "Crushed the morning workout! 💪"),
        FeedPost(id: "2", username: "sarah_lifts", imageName: "dummy2", kudos: 45, isKudoed: true, caption: "Leg day is the best day. 🦵"),
        FeedPost(id: "3", username: "mike_pump", imageName: "dummy3", kudos: 0, isKudoed: false, caption: "Rest day vibes.")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgGradient.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach($posts) { $post in
                            FeedPostView(post: $post)
                        }
                    }
                    .padding(.vertical)
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
                    // Future action for comment
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
