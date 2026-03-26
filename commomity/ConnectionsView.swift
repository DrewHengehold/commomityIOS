import SwiftUI

struct ConnectionsView: View {
    @State private var searchText = ""
    let connections = SampleData.connections

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {

                // Title
                HStack {
                    Text("Commomity")
                        .font(AppTheme.Fonts.playfair(36))
                        .foregroundColor(.black)
                        .padding(.leading, 25)
                    Spacer()
                }
                .padding(.top, 10)

                // Search bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(hex: "#8C8C8C"))
                        .font(.system(size: 16))
                    Text(searchText.isEmpty ? "search commomity..." : searchText)
                        .font(AppTheme.Fonts.playfair(24))
                        .foregroundColor(Color(hex: "#A5A5A5"))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 50)
                        .strokeBorder(Color(hex: "#D8D8D8"), lineWidth: 2.3)
                )
                .padding(.horizontal, 25)
                .padding(.top, 10)

                // Divider
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 1)
                    .padding(.top, 16)

                // Section header
                Text("People in Your Commomity...")
                    .font(AppTheme.Fonts.playfair(24, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 19)
                    .padding(.top, 10)

                // Extend card
                ExtendCommunityCard()
                    .padding(.horizontal, 19)
                    .padding(.top, 12)

                // Connection list
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(connections) { connection in
                            ConnectionRow(connection: connection)
                        }
                    }
                    .padding(.horizontal, 19)
                    .padding(.top, 16)
                }
            }
        }
    }
}

// MARK: - Extend Community Card
struct ExtendCommunityCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(hex: "#FBFBFB"))
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 1)

            HStack(spacing: 12) {
                Image(systemName: "message.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Color(hex: "#3A5FE8").opacity(0.85))
                    .frame(width: 56, height: 55)

                Text("Extend your commomity with your contacts")
                    .font(AppTheme.Fonts.roboto(24, weight: .medium))
                    .foregroundColor(Color(hex: "#5C5C5C"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 87)
    }
}

// MARK: - Connection Row
struct ConnectionRow: View {
    let connection: Connection

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            AvatarCircle(size: 73)

            VStack(alignment: .leading, spacing: 4) {
                Text(connection.name)
                    .font(AppTheme.Fonts.roboto(24, weight: .medium))
                    .foregroundColor(.black)

                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Color(hex: "#5C5C5C").opacity(0.85))
                    Text(connection.profession)
                        .font(AppTheme.Fonts.roboto(16, weight: .medium))
                        .foregroundColor(Color(hex: "#5C5C5C"))
                }

                LocationLabel(city: connection.city)

                Text("\(connection.role) – \(connection.profession)")
                    .font(AppTheme.Fonts.roboto(14, weight: .medium))
                    .foregroundColor(AppTheme.Colors.connectionBlue)
            }
        }
    }
}

#Preview {
    ConnectionsView()
}
