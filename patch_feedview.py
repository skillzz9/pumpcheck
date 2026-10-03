with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

target = """struct FeedPost: Identifiable {
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
    ]"""

replacement = """import FirebaseFirestore
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
    @State private var showCreatePost = false"""

if target in content:
    content = content.replace(target, replacement)
    print("Patched part 1")
else:
    print("Target 1 not found!")

target2 = """            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.pitchBlack, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}"""

replacement2 = """            .navigationBarTitleDisplayMode(.inline)
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
            print("Error fetching posts: \\(error.localizedDescription)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}"""

if target2 in content:
    content = content.replace(target2, replacement2)
    print("Patched part 2")
else:
    print("Target 2 not found!")

target3 = """        VStack(alignment: .leading, spacing: 8) {
            // Image area (Mocked as a rectangle with a photo icon)
            Rectangle()
                .fill(Theme.cardBackground)
                .aspectRatio(1.0, contentMode: .fit)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.taupeGrey.opacity(0.5))
                }
            
            // Action Buttons"""

replacement3 = """        VStack(alignment: .leading, spacing: 8) {
            
            // Header
            HStack {
                Text(post.username)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
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
            
            // Action Buttons"""

if target3 in content:
    content = content.replace(target3, replacement3)
    print("Patched part 3")
else:
    print("Target 3 not found!")

target4 = """            // Kudo count
            if post.kudos > 0 {
                Text("\\(post.kudos) \\(post.kudos == 1 ? "kudo" : "kudos")")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 12)
            }
        }
    }"""

replacement4 = """            // Kudo count
            if post.kudos > 0 {
                Text("\\(post.kudos) \\(post.kudos == 1 ? "kudo" : "kudos")")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 12)
            }
            
            // Caption
            if !post.caption.isEmpty {
                HStack(alignment: .top) {
                    Text(post.username).bold() + Text(" ") + Text(post.caption)
                }
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .padding(.horizontal, 12)
            }
        }
    }"""

if target4 in content:
    content = content.replace(target4, replacement4)
    print("Patched part 4")
else:
    print("Target 4 not found!")

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

