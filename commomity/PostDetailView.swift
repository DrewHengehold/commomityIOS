import SwiftUI
import MapKit

struct PostDetailView: View {
    let post: CommunityPost

    @Environment(AppRouter.self) private var router
    @Environment(UserSessionManager.self) private var session

    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var pinCoordinate: CLLocationCoordinate2D?

    private var tagColor: Color { Color(hex: post.intent.tagColorHex) }
    private var cardBg: Color { Color(hex: post.intent.cardColorHex) }
    private var isOwnPost: Bool { session.currentUserId == post.authorId }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                authorRow
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                contentSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                mapSection
                    .padding(.top, 24)

                messageButton
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 40)
            }
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
        .task { await geocodeCity(post.location) }
    }

    // MARK: - Author row

    private var authorRow: some View {
        HStack(spacing: 12) {
            AvatarCircle(size: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(post.author?.fullName ?? "Community Member")
                    .font(AppTheme.Fonts.roboto(16, weight: .bold))
                    .foregroundColor(.black)
                Text(timeAgo(post.createdAt))
                    .font(AppTheme.Fonts.roboto(13))
                    .foregroundColor(AppTheme.Colors.subtitleGray)
            }

            Spacer()

            Text(post.intent.label)
                .font(AppTheme.Fonts.roboto(13, weight: .bold))
                .foregroundColor(tagColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: AppTheme.pillRadius).fill(cardBg))
        }
    }

    // MARK: - Content section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.subject.uppercased())
                .font(AppTheme.Fonts.roboto(12, weight: .bold))
                .foregroundColor(tagColor)
                .kerning(1.2)

            Text(post.title)
                .font(AppTheme.Fonts.playfair(26))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)

            if let desc = post.description {
                Text(desc)
                    .font(AppTheme.Fonts.roboto(16))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }

            LocationLabel(city: post.location)
                .padding(.top, 4)
        }
    }

    // MARK: - Map section

    @ViewBuilder
    private var mapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Location")
                .font(AppTheme.Fonts.roboto(14, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)

            if let coordinate = pinCoordinate {
                Map(position: $mapPosition) {
                    Marker(post.location, coordinate: coordinate)
                        .tint(tagColor)
                }
                .frame(height: 220)
                .cornerRadius(AppTheme.cardRadius)
                .padding(.horizontal, 20)
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .fill(Color(hex: "#F0F0F0"))
                    .frame(height: 220)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "map")
                                .font(.system(size: 28))
                                .foregroundColor(.gray)
                            Text(post.location)
                                .font(AppTheme.Fonts.roboto(14, weight: .medium))
                                .foregroundColor(AppTheme.Colors.subtitleGray)
                        }
                    )
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Message button

    @ViewBuilder
    private var messageButton: some View {
        if isOwnPost {
            Text("This is your post")
                .font(AppTheme.Fonts.roboto(14))
                .foregroundColor(AppTheme.Colors.subtitleGray)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            Button {
                router.selectedTab = .inbox
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "message.fill")
                    Text("Send a Message")
                        .font(AppTheme.Fonts.roboto(18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(RoundedRectangle(cornerRadius: AppTheme.pillRadius).fill(tagColor))
                .shadow(color: tagColor.opacity(0.3), radius: 6, x: 0, y: 4)
            }
        }
    }

    // MARK: - Helpers

    private func geocodeCity(_ city: String) async {
        guard let placemarks = try? await CLGeocoder().geocodeAddressString(city),
              let loc = placemarks.first?.location else { return }
        pinCoordinate = loc.coordinate
        mapPosition = .region(MKCoordinateRegion(
            center: loc.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    private func timeAgo(_ date: Date) -> String {
        let secs = Date().timeIntervalSince(date)
        if secs < 3600   { return "\(max(1, Int(secs / 60)))m ago" }
        if secs < 86400  { return "\(Int(secs / 3600))h ago" }
        if secs < 604800 { return "\(Int(secs / 86400))d ago" }
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
        return f.string(from: date)
    }
}

// MARK: - Previews

#Preview("Offering Housing") {
    struct Preview: View {
        @State var router = AppRouter()
        @State var session = UserSessionManager()
        var body: some View {
            NavigationStack {
                PostDetailView(post: CommunityPost(
                    id: UUID(), authorId: UUID(),
                    intent: .offering, subject: "Housing",
                    title: "Private room available in 2BR apartment",
                    description: "Quiet, furnished room near Caltrain. Utilities included. Month-to-month preferred.",
                    location: "San Francisco",
                    status: .published, expiresAt: nil, createdAt: Date()
                ))
                .environment(router)
                .environment(session)
            }
        }
    }
    return Preview()
}

#Preview("Seeking Career Advice") {
    struct Preview: View {
        @State var router = AppRouter()
        @State var session = UserSessionManager()
        var body: some View {
            NavigationStack {
                PostDetailView(post: CommunityPost(
                    id: UUID(), authorId: UUID(),
                    intent: .seeking, subject: "Career Advice",
                    title: "Looking for a mentor in product design",
                    description: "Recent grad looking for someone with 5+ years of UX/product experience to meet monthly.",
                    location: "Oakland",
                    status: .published, expiresAt: nil,
                    createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
                ))
                .environment(router)
                .environment(session)
            }
        }
    }
    return Preview()
}
