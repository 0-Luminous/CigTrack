import SwiftUI

enum DashboardBackgroundStyle: Int, CaseIterable, Identifiable {
    case sunrise
    case amber
    case ocean
    case forest
    case midnight

    static let `default`: DashboardBackgroundStyle = .sunrise

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .sunrise: return NSLocalizedString("Sunrise", comment: "Dashboard background option")
        case .amber: return NSLocalizedString("Amber Glow", comment: "Dashboard background option")
        case .ocean: return NSLocalizedString("Ocean Tide", comment: "Dashboard background option")
        case .forest: return NSLocalizedString("Forest Breeze", comment: "Dashboard background option")
        case .midnight: return NSLocalizedString("Midnight", comment: "Dashboard background option")
        }
    }

    var previewGradient: LinearGradient {
        LinearGradient(colors: backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: backgroundColors, startPoint: .top, endPoint: .bottom)
    }

    var circleGradient: RadialGradient {
        RadialGradient(colors: circleColors, center: .center, startRadius: 40, endRadius: 170)
    }

    var primaryTextColor: Color {
        switch self {
        case .sunrise, .amber:
            return Color.black.opacity(0.88)
        case .ocean, .forest, .midnight:
            return Color.white.opacity(0.95)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .sunrise, .amber:
            return Color.black.opacity(0.7)
        case .ocean, .forest, .midnight:
            return Color.white.opacity(0.78)
        }
    }

    var circleTextColor: Color {
        switch self {
        case .sunrise, .amber:
            return Color.black.opacity(0.85)
        case .ocean, .forest, .midnight:
            return Color.white.opacity(0.95)
        }
    }

    private var backgroundColors: [Color] {
        switch self {
        case .sunrise:
            return [
                Color(red: 1.00, green: 0.74, blue: 0.22),
                Color(red: 0.98, green: 0.58, blue: 0.16)
            ]
        case .amber:
            return [
                Color(red: 1.00, green: 0.63, blue: 0.29),
                Color(red: 0.93, green: 0.34, blue: 0.20)
            ]
        case .ocean:
            return [
                Color(red: 0.21, green: 0.58, blue: 0.90),
                Color(red: 0.02, green: 0.33, blue: 0.60)
            ]
        case .forest:
            return [
                Color(red: 0.33, green: 0.71, blue: 0.47),
                Color(red: 0.11, green: 0.40, blue: 0.24)
            ]
        case .midnight:
            return [
                Color(red: 0.36, green: 0.24, blue: 0.60),
                Color(red: 0.10, green: 0.11, blue: 0.29)
            ]
        }
    }

    private var circleColors: [Color] {
        switch self {
        case .sunrise:
            return [
                Color(red: 1.00, green: 0.66, blue: 0.20),
                Color(red: 0.98, green: 0.53, blue: 0.13)
            ]
        case .amber:
            return [
                Color(red: 1.00, green: 0.48, blue: 0.18),
                Color(red: 0.98, green: 0.30, blue: 0.14)
            ]
        case .ocean:
            return [
                Color(red: 0.41, green: 0.77, blue: 0.95),
                Color(red: 0.09, green: 0.45, blue: 0.78)
            ]
        case .forest:
            return [
                Color(red: 0.63, green: 0.87, blue: 0.58),
                Color(red: 0.20, green: 0.55, blue: 0.35)
            ]
        case .midnight:
            return [
                Color(red: 0.74, green: 0.51, blue: 0.98),
                Color(red: 0.40, green: 0.23, blue: 0.67)
            ]
        }
    }
}
