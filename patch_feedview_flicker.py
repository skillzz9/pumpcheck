import re

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "r") as f:
    content = f.read()

# 1. Add new states to FeedPostView
target_struct = """struct FeedPostView: View {
    @Binding var post: FeedPost
    @Binding var selectedPostId: String?
    var onNavigateToProfile: (String, String) -> Void
    
    var body: some View {"""

replacement_struct = """struct FeedPostView: View {
    @Binding var post: FeedPost
    @Binding var selectedPostId: String?
    var onNavigateToProfile: (String, String) -> Void
    
    @State private var profileImageData: Data? = nil
    @State private var sliderValue: Double = 0
    
    var body: some View {"""

content = content.replace(target_struct, replacement_struct)

# 2. Replace Header
target_header = """            // Header
            HStack {
                Button { onNavigateToProfile(post.userId, post.username) } label: {
                    Text(post.username)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                .padding(.vertical, 8)
                .padding(.trailing, 16)
                }
                Spacer()
                Text(post.date, style: .time)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 16)"""

replacement_header = """            // Header
            HStack {
                Button { onNavigateToProfile(post.userId, post.username) } label: {
                    HStack(spacing: 8) {
                        Text(post.username)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            
                        if let data = profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Theme.cardBackground)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Theme.taupeGrey)
                                )
                        }
                    }
                }
                .padding(.vertical, 8)
                Spacer()
                Text(post.date, style: .time)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .task {
                let db = Firestore.firestore()
                if let doc = try? await db.collection("users").document(post.userId).getDocument(),
                   let data = doc.data(),
                   let pfpStr = data["profilePictureBase64"] as? String,
                   let imgData = Data(base64Encoded: pfpStr) {
                    self.profileImageData = imgData
                }
            }"""

content = content.replace(target_header, replacement_header)

# 3. Replace Image Area
# We must use regex because the TabView block has been modified previously with debug code
pattern_image_area = r"            if post\.photos\.count > 1 \{.*?else if let firstPhoto = post\.photos\.first"

replacement_image_area = """            if post.photos.count > 1 {
                VStack(spacing: 0) {
                    let currentIndex = Int(sliderValue)
                    if currentIndex >= 0 && currentIndex < post.photos.count,
                       let data = Data(base64Encoded: post.photos[currentIndex]),
                       let uiImage = UIImage(data: data) {
                        
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
                        Slider(value: $sliderValue, in: 0...Double(post.photos.count - 1), step: 1.0)
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
            } else if let firstPhoto = post.photos.first"""

content = re.sub(pattern_image_area, replacement_image_area, content, flags=re.DOTALL)

with open("PumpCheck.swiftpm/Onboarding/FeedView.swift", "w") as f:
    f.write(content)

print("Patched FeedView with Flicker Slider and PFP successfully!")
