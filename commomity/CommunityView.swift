import SwiftUI

struct CommunityView: View {
    @Environment(PostStore.self) private var postStore
    @Environment(UserSessionManager.self) private var session
    @State private var selectedIntent: PostIntent? = nil
    @State private var showCreatePost: Bool = false

    var filteredPosts: [CommunityPost] {
        postStore.posts(for: selectedIntent)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    HamburgerIcon()
                        .padding(.leading, 29)
                    Spacer()
                    Text("Commomity")
                        .font(AppTheme.Fonts.playfair(36))
                        .foregroundColor(.black)
                    Spacer()
                    Button {
                        showCreatePost = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    .padding(.trailing, 12)

                    AvatarCircle(size: 40)
                        .padding(.trailing, 29)

                }
                .padding(.top, 0)
                .padding(.bottom, 4)
                .frame(height: 60) //Added to Fix issue with large white space

                // Scrollable filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterPill(
                            label: PostIntent.offering.label,
                            isSelected: selectedIntent == .offering,
                            action: {
                                selectedIntent = selectedIntent == .offering ? nil : .offering
                            }
                        )
                        FilterPill(
                            label: PostIntent.seeking.label,
                            isSelected: selectedIntent == .seeking,
                            action: {
                                selectedIntent = selectedIntent == .seeking ? nil : .seeking
                            }
                        )
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 6)
                }

                // Posts scroll
                if postStore.isLoading && postStore.posts.isEmpty {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Spacer()
                } else if filteredPosts.isEmpty && !postStore.isLoading {
                    Spacer()
                    Text("No posts yet — be the first to share something!")
                        .font(AppTheme.Fonts.roboto(16, weight: .medium))
                        .foregroundColor(AppTheme.Colors.subtitleGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            ForEach(filteredPosts) { post in
                                NavigationLink(value: Route.postDetail(post.id.uuidString)) {
                                    CommunityCard(post: post)
                                        .padding(.horizontal, 20)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        await postStore.fetchPublished()
                    }
                }
            }
        }
        .task {
            await postStore.fetchPublished()
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView()
                .environment(postStore)
                .environment(session)
        }
    }
}

// MARK: - Community Card
struct CommunityCard: View {
    let post: CommunityPost

    private var cardBg: Color {
        Color(hex: post.intent.cardColorHex)
    }

    private var tagColor: Color {
        Color(hex: post.intent.tagColorHex)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .fill(cardBg)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)

            HStack(alignment: .center, spacing: 12) {
                // Avatar
                AvatarCircle(size: 73)
                    .padding(.leading, 4)

                VStack(alignment: .leading, spacing: 4) {
                    
                    HStack(alignment: .center, spacing: 6) {
                        Text("\(post.intent.label) \(post.subject)")
                            .font(AppTheme.Fonts.roboto(20, weight: .bold))
                            .foregroundColor(tagColor)
                            .lineLimit(2)
                        
                        Text(post.title)
                            .font(AppTheme.Fonts.roboto(20, weight: .bold))
                            .foregroundColor(.black)
                            .lineLimit(2)
                    }
                    
                    
                    

                    
                    if let description = post.description {
                        Text(description)
                            .font(AppTheme.Fonts.roboto(12))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    LocationLabel(city: post.location)
                        .padding(.top, 2)
                }

                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 18)
        }
        .frame(height: 109)
    }
}

// MARK: - Previews

#Preview("Community View") {
    struct Preview: View {
        @State var postStore = PostStore.preview
        @State var session = UserSessionManager()
        var body: some View {
            CommunityView()
                .environment(postStore)
                .environment(session)
        }
    }
    return Preview()
}

#Preview("Community Card - Offering Housing") {
    CommunityCard(post: CommunityPost(
        id: UUID(),
        authorId: UUID(),
        intent: .offering,
        subject: "Housing",
        title: "Private room available",
        description: "Quiet, furnished room near Caltrain.",
        location: "San Francisco",
        status: .published,
        expiresAt: nil,
        createdAt: Date()
    ))
    .padding()
}

#Preview("Community Card - Seeking Career Advice") {
    CommunityCard(post: CommunityPost(
        id: UUID(),
        authorId: UUID(),
        intent: .seeking,
        subject: "Career Advice",
        title: "Looking for a product design mentor",
        description: "Recent grad seeking monthly mentorship sessions.",
        location: "Oakland",
        status: .published,
        expiresAt: nil,
        createdAt: Date()
    ))
    .padding()
}

#Preview("Community Card - Seeking Work") {
    CommunityCard(post: CommunityPost(
        id: UUID(),
        authorId: UUID(),
        intent: .seeking,
        subject: "Work",
        title: "Available for part-time contracts",
        description: "Full-stack developer, React / Swift / Node.",
        location: "Berkeley",
        status: .published,
        expiresAt: nil,
        createdAt: Date()
    ))
    .padding()
}

#Preview("Community Card - All Types") {
    ScrollView {
        VStack(spacing: 14) {
            ForEach(SampleData.communityPosts) { post in
                CommunityCard(post: post)
            }
        }
        .padding(20)
    }
}

#Preview("Community Card - Long Title") {
    CommunityCard(post: CommunityPost(
        id: UUID(),
        authorId: UUID(),
        intent: .seeking,
        subject: "Career Advice",
        title: "Seeking an experienced mentor for a long-term professional growth journey",
        description: "Looking for someone with deep expertise in product strategy.",
        location: "San Francisco",
        status: .published,
        expiresAt: nil,
        createdAt: Date()
    ))
    .padding()
}

#Preview("Community - Dark Mode") {
    struct Preview: View {
        @State var postStore = PostStore.preview
        @State var session = UserSessionManager()
        var body: some View {
            CommunityView()
                .environment(postStore)
                .environment(session)
                .preferredColorScheme(.dark)
        }
    }
    return Preview()
}
