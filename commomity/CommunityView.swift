import SwiftUI

struct CommunityView: View {
    let posts = SampleData.communityPosts

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
                    Color.clear.frame(width: 35)
                }
                .padding(.top, 14)

                // Scrollable filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterPill(label: "Offering")
                        FilterPill(label: "Seeking")
                        FilterPill(label: "Housing")
                        FilterPill(label: "Small Job")
                        FilterPill(label: "Yard Work")
                    }
                    .padding(.horizontal, 22)
                }
                .padding(.top, 10)

                // Posts scroll
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(posts) { post in
                            CommunityCard(post: post)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Community Card
struct CommunityCard: View {
    let post: CommunityPost

    private var cardBg: Color {
        post.tag.isSeeking ? AppTheme.Colors.seekingCard : AppTheme.Colors.offeringCard
    }

    private var tagColor: Color {
        post.tag.isSeeking ? AppTheme.Colors.seekingTag : AppTheme.Colors.offeringTag
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
                        Text(post.personName)
                            .font(AppTheme.Fonts.roboto(24, weight: .bold))
                            .foregroundColor(.black)

                        Circle()
                            .fill(Color.black)
                            .frame(width: 5, height: 5)

                        Text(post.tag.label)
                            .font(AppTheme.Fonts.roboto(16, weight: .bold))
                            .foregroundColor(tagColor)
                    }

                    Text(post.motherName)
                        .font(AppTheme.Fonts.roboto(12))
                        .foregroundColor(.black.opacity(0.4))

                    LocationLabel(city: post.city)
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
    CommunityView()
}
#Preview("Community Card - Offering Housing") {
    CommunityCard(post: CommunityPost(
        personName: "Drew",
        avatarImageName: nil,
        motherName: "Mother Rebecca Nagel",
        city: "San Francisco",
        tag: .offeringHousing
    ))
    .padding()
}

#Preview("Community Card - Seeking Career Advice") {
    CommunityCard(post: CommunityPost(
        personName: "Ella",
        avatarImageName: nil,
        motherName: "Mother Michelle Coddington",
        city: "Oakland",
        tag: .seekingCareerAdvice
    ))
    .padding()
}

#Preview("Community Card - Seeking Work") {
    CommunityCard(post: CommunityPost(
        personName: "Michael",
        avatarImageName: nil,
        motherName: "Mother Sarah Johnson",
        city: "Berkeley",
        tag: .seekingWork
    ))
    .padding()
}

#Preview("Community Card - All Types") {
    ScrollView {
        VStack(spacing: 14) {
            CommunityCard(post: CommunityPost(
                personName: "Drew",
                avatarImageName: nil,
                motherName: "Mother Rebecca Nagel",
                city: "San Francisco",
                tag: .offeringHousing
            ))
            
            CommunityCard(post: CommunityPost(
                personName: "Ella",
                avatarImageName: nil,
                motherName: "Mother Michelle Coddington",
                city: "Oakland",
                tag: .seekingCareerAdvice
            ))
            
            CommunityCard(post: CommunityPost(
                personName: "Alex",
                avatarImageName: nil,
                motherName: "Mother Jennifer Smith",
                city: "Berkeley",
                tag: .seekingHousing
            ))
            
            CommunityCard(post: CommunityPost(
                personName: "Jordan",
                avatarImageName: nil,
                motherName: "Mother Patricia Lee",
                city: "San Jose",
                tag: .seekingWork
            ))
        }
        .padding(20)
    }
}

#Preview("Community Card - Long Names") {
    CommunityCard(post: CommunityPost(
        personName: "Christopher Alexander",
        avatarImageName: nil,
        motherName: "Mother Elizabeth Catherine Thompson",
        city: "San Francisco",
        tag: .seekingCareerAdvice
    ))
    .padding()
}

#Preview("Community - Dark Mode") {
    CommunityView()
        .preferredColorScheme(.dark)
}

