import SwiftUI

// MARK: - Hamburger / Filter Icon
struct HamburgerIcon: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Rectangle().frame(width: 20, height: 2.5).foregroundColor(Color(hex: "#796F6F"))
            Rectangle().frame(width: 17, height: 2.5).foregroundColor(Color(hex: "#796F6F"))
            Rectangle().frame(width: 13, height: 2.5).foregroundColor(Color(hex: "#796F6F"))
        }
    }
}

// MARK: - Bottom Navigation Bar
enum NavTab: Int, CaseIterable {
    case home, inbox, connections, map

    var iconName: String {
        switch self {
        case .home:        return "house.fill"
        case .inbox:       return "tray.fill"
        case .connections: return "person.2.fill"
        case .map:         return "map.fill"
        }
    }

    var label: String {
        switch self {
        case .home:        return "Home"
        case .inbox:       return "Inbox"
        case .connections: return "Connections"
        case .map:         return "Map"
        }
    }
}

struct BottomNavBar: View {
    @Binding var selectedTab: NavTab

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 50)
                .fill(AppTheme.Colors.navBar)
                .frame(height: 82.5)

            HStack(spacing: 0) {
                ForEach(NavTab.allCases, id: \.rawValue) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        ZStack {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 50)
                                    .fill(AppTheme.Colors.navBarSelected)
                                    .frame(width: 106, height: 74)
                            }
                            Image(systemName: tab.iconName)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.black.opacity(0.85))
                                .frame(width: 106, height: 74)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 414)
    }
}

// MARK: - Avatar Circle
struct AvatarCircle: View {
    var imageName: String? = nil
    var size: CGFloat = 60
    var backgroundColor: Color = AppTheme.Colors.tileBackground

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
            if let name = imageName {
                Image(name)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
    }
}

// MARK: - Tag Badge
struct TagBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AppTheme.Fonts.roboto(15, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let label: String
    var isSelected: Bool = false

    var body: some View {
        Text(label)
            .font(AppTheme.Fonts.roboto(15, weight: .bold))
            .foregroundColor(AppTheme.Colors.filterPillText)
            .frame(width: 77, height: 22)
            .background(
                RoundedRectangle(cornerRadius: 50)
                    .fill(AppTheme.Colors.filterPill)
            )
    }
}

// MARK: - Location Label
struct LocationLabel: View {
    let city: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "location.fill")
                .font(.system(size: 9))
                .foregroundColor(AppTheme.Colors.offeringTag)
            Text(city)
                .font(AppTheme.Fonts.roboto(16, weight: .bold))
                .foregroundColor(AppTheme.Colors.offeringTag)
        }
    }
}

// MARK: - Skill Pill Button
struct SkillPillButton: View {
    let label: String
    var isSelected: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            ZStack {
                // Shadow pill
                RoundedRectangle(cornerRadius: 50)
                    .fill(isSelected ? AppTheme.Colors.selectedPillShadow : Color.black)
                    .offset(x: 3, y: 3)
                // Main pill
                RoundedRectangle(cornerRadius: 50)
                    .fill(isSelected ? AppTheme.Colors.selectedPillBg : Color.white)
                Text(label)
                    .font(AppTheme.Fonts.roboto(24, weight: isSelected ? .bold : .medium))
                    .foregroundColor(.black)
            }
            .frame(height: 39)
        }
        .buttonStyle(.plain)
    }
}
