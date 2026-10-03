import SwiftUI

struct CommentModalView: View {
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
                VStack {
                    Text("No comments yet.")
                        .foregroundColor(Theme.textSecondary)
                        .padding(.top, 40)
                }
                .frame(maxWidth: .infinity)
            }
            .background(Theme.bgGradient)
            
            // Write a comment section
            HStack {
                TextField("Add a comment...", text: $commentText)
                    .textFieldStyle(PumpTextFieldStyle())
                
                Button {
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
