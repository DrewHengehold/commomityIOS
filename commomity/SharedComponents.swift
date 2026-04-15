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
// NavTab enum is defined in Models.swift

struct BottomNavBar: View {
    @Binding var selectedTab: NavTab

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 50)
                .fill(AppTheme.Colors.navBar)

            HStack(spacing: 0) {
                ForEach(NavTab.allCases, id: \.rawValue) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        ZStack {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 50)
                                    .fill(AppTheme.Colors.navBarSelected)
                                    .padding(.horizontal, 4)
                            }
                            Image(systemName: tab.iconName)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.black.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 74)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 82.5)
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
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            Text(label)
                .font(AppTheme.Fonts.roboto(15, weight: .bold))
                .foregroundColor(AppTheme.Colors.filterPillText)
                .frame(width: 77, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 50)
                        .fill(isSelected
                              ? AppTheme.Colors.filterPillText.opacity(0.15)
                              : AppTheme.Colors.filterPill)
                )
        }
        .buttonStyle(.plain)
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
