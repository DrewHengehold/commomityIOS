import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        static let background = Color.white
        static let appYellow = Color(hex: "#FFC14D")
        static let seekingTag = Color(hex: "#9D6402")
        static let offeringTag = Color(hex: "#146974")
        static let seekingCard = Color(hex: "#F0D5B6")
        static let offeringCard = Color(hex: "#C9E3E7")
        static let filterPill = Color(hex: "#FCC8FF")
        static let filterPillText = Color(hex: "#301D2E").opacity(0.48)
        static let navBar = Color(hex: "#D9D9D9")
        static let navBarSelected = Color(hex: "#5F61FF").opacity(0.3)
        static let subtitleGray = Color(hex: "#818181")
        static let cardBackground = Color(hex: "#FBFBFB")
        static let tileBackground = Color(hex: "#D9D9D9")
        static let childBlue = Color(hex: "#4668FF")
        static let parentGreen = Color(hex: "#0CA609")
        static let selectedPillBg = Color(hex: "#A6D3FF")
        static let selectedPillShadow = Color(hex: "#0150B0")
        static let connectionBlue = Color(hex: "#2700C2")
        static let mapPopupBg = Color(hex: "#676767")
    }

    // MARK: - Fonts
    struct Fonts {
        static func playfair(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
            .custom("PlayfairDisplay-SemiBold", size: size)
        }
        static func roboto(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            switch weight {
            case .bold:   return .custom("Roboto-Bold", size: size)
            case .medium: return .custom("Roboto-Medium", size: size)
            case .light:  return .custom("Roboto-Light", size: size)
            default:      return .custom("Roboto-Regular", size: size)
            }
        }
    }

    // MARK: - Layout
    static let screenWidth: CGFloat = 450
    static let screenHeight: CGFloat = 975
    static let cornerRadius: CGFloat = 28
    static let cardRadius: CGFloat = 21
    static let pillRadius: CGFloat = 50
}

// MARK: - Color hex init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
