import re

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

target1 = """    @State private var posts: [FeedPost] = []
    @State private var isLoading = true
    @State private var showCreatePost = false
    @State private var selectedPostId: String? = nil"""

replacement1 = """    @State private var posts: [FeedPost] = []
    @State private var isLoading = true
    @State private var showCreatePost = false
    @State private var selectedPostId: String? = nil
    
    // Programmatic Navigation State
    @State private var navToProfileId: String? = nil
    @State private var navToProfileName: String? = nil"""

target2 = """            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {"""

replacement2 = """            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(isPresented: Binding(
                get: { navToProfileId != nil },
                set: { if !$0 { navToProfileId = nil; navToProfileName = nil } }
            )) {
                if let uid = navToProfileId, let uname = navToProfileName {
                    PublicProfileView(userId: uid, username: uname)
                }
            }
            .toolbar {"""

target3 = """                        ForEach($posts) { $post in
                            FeedPostView(post: $post, selectedPostId: $selectedPostId)
                        }"""

replacement3 = """                        ForEach($posts) { $post in
                            FeedPostView(
                                post: $post, 
                                selectedPostId: $selectedPostId,
                                onNavigateToProfile: { uid, uname in
                                    navToProfileId = uid
                                    navToProfileName = uname
                                }
                            )
                        }"""

target4 = """                if let selectedId = selectedPostId, let index = posts.firstIndex(where: { $0.id == selectedId }) {
                    CommentModalView(viewModel: viewModel, post: $posts[index], isPresented: Binding(
                        get: { selectedPostId != nil },
                        set: { if !$0 { selectedPostId = nil } }
                    ))"""

replacement4 = """                if let selectedId = selectedPostId, let index = posts.firstIndex(where: { $0.id == selectedId }) {
                    CommentModalView(
                        viewModel: viewModel, 
                        post: $posts[index], 
                        isPresented: Binding(
                            get: { selectedPostId != nil },
                            set: { if !$0 { selectedPostId = nil } }
                        ),
                        onNavigateToProfile: { uid, uname in
                            // Dismiss modal then navigate
                            selectedPostId = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navToProfileId = uid
                                navToProfileName = uname
                            }
                        }
                    )"""

target5 = """struct FeedPostView: View {
    @Binding var post: FeedPost
    @Binding var selectedPostId: String?"""

replacement5 = """struct FeedPostView: View {
    @Binding var post: FeedPost
    @Binding var selectedPostId: String?
    var onNavigateToProfile: (String, String) -> Void"""

target6 = """            // Header
            HStack {
                NavigationLink(destination: PublicProfileView(userId: post.userId, username: post.username)) {
                    Text(post.username)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()"""

replacement6 = """            // Header
            HStack {
                Button {
                    onNavigateToProfile(post.userId, post.username)
                } label: {
                    Text(post.username)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .padding(.vertical, 4)
                        .padding(.trailing, 16) // larger hit area
                }
                Spacer()"""

target7 = """            // Caption
            if !post.caption.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    NavigationLink(destination: PublicProfileView(userId: post.userId, username: post.username)) {
                        Text(post.username).bold()
                            .foregroundColor(Theme.textPrimary)
                    }
                    Text(post.caption)"""

replacement7 = """            // Caption
            if !post.caption.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Button {
                        onNavigateToProfile(post.userId, post.username)
                    } label: {
                        Text(post.username).bold()
                            .foregroundColor(Theme.textPrimary)
                    }
                    Text(post.caption)"""

if target1 in content:
    content = content.replace(target1, replacement1)
    content = content.replace(target2, replacement2)
    content = content.replace(target3, replacement3)
    content = content.replace(target4, replacement4)
    content = content.replace(target5, replacement5)
    content = content.replace(target6, replacement6)
    content = content.replace(target7, replacement7)
    with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
        f.write(content)
    print("Patched FeedView successfully!")
else:
    print("Target not found!")
