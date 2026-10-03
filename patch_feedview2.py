import re

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

content = re.sub(
    r"@State private var selectedPostId: String\? = nil",
    """@State private var selectedPostId: String? = nil\n    @State private var navToProfileId: String? = nil\n    @State private var navToProfileName: String? = nil""",
    content
)

content = re.sub(
    r"\.toolbarColorScheme\(\.dark, for: \.navigationBar\)",
    """.toolbarColorScheme(.dark, for: .navigationBar)\n            .navigationDestination(isPresented: Binding(\n                get: { navToProfileId != nil },\n                set: { if !$0 { navToProfileId = nil; navToProfileName = nil } }\n            )) {\n                if let uid = navToProfileId, let uname = navToProfileName {\n                    PublicProfileView(userId: uid, username: uname)\n                }\n            }""",
    content
)

content = content.replace("FeedPostView(post: $post, selectedPostId: $selectedPostId)", 
"""FeedPostView(
                                post: $post, 
                                selectedPostId: $selectedPostId,
                                onNavigateToProfile: { uid, uname in
                                    navToProfileId = uid
                                    navToProfileName = uname
                                }
                            )""")

content = content.replace("""CommentModalView(viewModel: viewModel, post: $posts[index], isPresented: Binding(
                        get: { selectedPostId != nil },
                        set: { if !$0 { selectedPostId = nil } }
                    ))""",
"""CommentModalView(
                        viewModel: viewModel, 
                        post: $posts[index], 
                        isPresented: Binding(
                            get: { selectedPostId != nil },
                            set: { if !$0 { selectedPostId = nil } }
                        ),
                        onNavigateToProfile: { uid, uname in
                            selectedPostId = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navToProfileId = uid
                                navToProfileName = uname
                            }
                        }
                    )""")

content = content.replace("""@Binding var selectedPostId: String?""",
"""@Binding var selectedPostId: String?
    var onNavigateToProfile: (String, String) -> Void""")

# Replace the NavigationLink in Header
content = re.sub(
    r"NavigationLink\(destination: PublicProfileView\(userId: post\.userId, username: post\.username\)\) \{\n(.*?)Text\(post\.username\)\n(.*?).font\(\.system\(size: 16, weight: \.bold, design: \.rounded\)\)\n(.*?).foregroundColor\(Theme\.textPrimary\)\n(.*?)\}",
    """Button { onNavigateToProfile(post.userId, post.username) } label: {\n\\1Text(post.username)\n\\2.font(.system(size: 16, weight: .bold, design: .rounded))\n\\3.foregroundColor(Theme.textPrimary)\n\\4.padding(.vertical, 8)\n\\4.padding(.trailing, 16)\n\\4}""",
    content
)

# Replace the NavigationLink in Caption
content = re.sub(
    r"NavigationLink\(destination: PublicProfileView\(userId: post\.userId, username: post\.username\)\) \{\n(.*?)Text\(post\.username\)\.bold\(\)\n(.*?).foregroundColor\(Theme\.textPrimary\)\n(.*?)\}",
    """Button { onNavigateToProfile(post.userId, post.username) } label: {\n\\1Text(post.username).bold()\n\\2.foregroundColor(Theme.textPrimary)\n\\3}""",
    content
)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

print("Patched FeedView successfully!")
