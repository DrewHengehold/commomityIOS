import SwiftUI
import MapKit

struct MapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.8716, longitude: -122.2727),
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )
    @State private var searchText = ""
    @State private var showPopup = true

    let community = SampleData.mapCommunity

    var body: some View {
        ZStack(alignment: .top) {
            // Full map background
            Map(coordinateRegion: $region)
                .ignoresSafeArea()
                .cornerRadius(AppTheme.cornerRadius)

            VStack(spacing: 0) {
                // Title
                HStack {
                    Text("Community Finder")
                        .font(AppTheme.Fonts.playfair(36, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.leading, 9)
                    Spacer()
                }
                .padding(.top, 10)

                // Divider
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 1)
                    .padding(.top, 4)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#060101"))
                    Text(searchText.isEmpty ? "search" : searchText)
                        .font(AppTheme.Fonts.playfair(24))
                        .foregroundColor(Color(hex: "#160606"))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 50)
                        .fill(Color.white.opacity(0.49))
                        .overlay(
                            RoundedRectangle(cornerRadius: 50)
                                .strokeBorder(Color(hex: "#D8D8D8"), lineWidth: 2.3)
                        )
                )
                .padding(.horizontal, 21)
                .padding(.top, 10)

                Spacer()

                // Community popup (bottom right)
                if showPopup {
                    HStack {
                        Spacer()
                        CommunityPopup(community: community)
                            .padding(.trailing, 18)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

// MARK: - Community Popup Card
struct CommunityPopup: View {
    let community: MapCommunity

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.Colors.mapPopupBg)
                    .frame(width: 240)

                VStack(alignment: .leading, spacing: 6) {
                    // Community name
                    Text(community.name)
                        .font(AppTheme.Fonts.roboto(20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 16)
                        .padding(.horizontal, 14)

                    // Member count
                    Text("\(community.memberCount) moms")
                        .font(AppTheme.Fonts.roboto(14, weight: .bold))
                        .foregroundColor(Color(hex: "#9D9D9D"))
                        .padding(.horizontal, 14)

                    // Member tiles
                    VStack(spacing: 8) {
                        ForEach(community.members) { member in
                            MemberTile(member: member)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
            }
            .frame(width: 240)

            // Callout pointer
            Rectangle()
                .fill(AppTheme.Colors.mapPopupBg)
                .frame(width: 16.5, height: 48.5)
                .offset(x: -95)
        }
    }
}

// MARK: - Member Tile
struct MemberTile: View {
    let member: Connection

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.Colors.tileBackground)
                .frame(height: 50)

            HStack(spacing: 10) {
                AvatarCircle(size: 42)
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(AppTheme.Fonts.roboto(20, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    Text("\(member.role) – \(member.profession)")
                        .font(AppTheme.Fonts.roboto(14, weight: .medium))
                        .foregroundColor(AppTheme.Colors.connectionBlue)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 8)
        }
    }
}

#Preview {
    MapView()
}
