import SwiftUI

enum DashboardBackgroundStyle: Int, CaseIterable, Identifiable {
    case sunrise
    case amber
    case ocean
    case forest
    case midnight
    case sunsetAura
    case oceanDeep
    case cosmicPurple
    case mintBreeze
    case lavaBurst
    case iceCrystal
    case coralSunset
    case auroraGlow
    case forestEmerald
    case skyMorning
    case pinkNebula
    case electricNight

    static let `default`: DashboardBackgroundStyle = .sunrise
    static let defaultDark: DashboardBackgroundStyle = .midnight
    static func `default`(for scheme: ColorScheme) -> DashboardBackgroundStyle {
        scheme == .dark ? defaultDark : `default`
    }
    static let appearanceOptions: [DashboardBackgroundStyle] = [
        .sunsetAura,
        .coralSunset,
        .sunrise,
        .amber,
        .lavaBurst,
        .pinkNebula,
        .cosmicPurple,
        .midnight,
        .electricNight,
        .oceanDeep,
        .ocean,
        .skyMorning,
        .iceCrystal,
        .auroraGlow,
        .mintBreeze,
        .forest,
        .forestEmerald
    ]

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .iceCrystal: return NSLocalizedString("Ice Crystal", comment: "Dashboard background option")
        case .sunrise: return NSLocalizedString("Sunrise", comment: "Dashboard background option")
        case .amber: return NSLocalizedString("Amber Glow", comment: "Dashboard background option")
        case .sunsetAura: return NSLocalizedString("Sunset Aura", comment: "Dashboard background option")
        case .coralSunset: return NSLocalizedString("Coral Sunset", comment: "Dashboard background option")
        case .ocean: return NSLocalizedString("Ocean Tide", comment: "Dashboard background option")
        case .skyMorning: return NSLocalizedString("Sky Morning", comment: "Dashboard background option")
        case .forest: return NSLocalizedString("Forest Breeze", comment: "Dashboard background option")
        
        
        case .oceanDeep: return NSLocalizedString("Ocean Deep", comment: "Dashboard background option")
        
        case .mintBreeze: return NSLocalizedString("Mint Breeze", comment: "Dashboard background option")
        case .lavaBurst: return NSLocalizedString("Lava Burst", comment: "Dashboard background option")
        
        
        case .auroraGlow: return NSLocalizedString("Aurora Glow", comment: "Dashboard background option")
        case .forestEmerald: return NSLocalizedString("Forest Emerald", comment: "Dashboard background option")
        
        case .pinkNebula: return NSLocalizedString("Pink Nebula", comment: "Dashboard background option")
        case .electricNight: return NSLocalizedString("Electric Night", comment: "Dashboard background option")
        case .cosmicPurple: return NSLocalizedString("Cosmic Purple", comment: "Dashboard background option")
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
        case .sunrise, .amber, .sunsetAura, .mintBreeze, .iceCrystal, .coralSunset, .auroraGlow, .skyMorning:
            return Color.black.opacity(0.88)
        case .ocean, .forest, .midnight, .oceanDeep, .cosmicPurple, .lavaBurst, .forestEmerald, .pinkNebula, .electricNight:
            return Color.white.opacity(0.95)
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .sunrise, .amber, .sunsetAura, .mintBreeze, .iceCrystal, .coralSunset, .auroraGlow, .skyMorning:
            return Color.black.opacity(0.7)
        case .ocean, .forest, .midnight, .oceanDeep, .cosmicPurple, .lavaBurst, .forestEmerald, .pinkNebula, .electricNight:
            return Color.white.opacity(0.78)
        }
    }

    var circleTextColor: Color {
        switch self {
        case .sunrise, .amber, .sunsetAura, .mintBreeze, .iceCrystal, .coralSunset, .auroraGlow, .skyMorning:
            return Color.black.opacity(0.85)
        case .ocean, .forest, .midnight, .oceanDeep, .cosmicPurple, .lavaBurst, .forestEmerald, .pinkNebula, .electricNight:
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
        case .sunsetAura:
            return [
                Color(red: 1.00, green: 0.37, blue: 0.43),
                Color(red: 1.00, green: 0.76, blue: 0.44)
            ]
        case .oceanDeep:
            return [
                Color(red: 0.18, green: 0.19, blue: 0.57),
                Color(red: 0.11, green: 1.00, blue: 1.00)
            ]
        case .cosmicPurple:
            return [
                Color(red: 0.50, green: 0.00, blue: 1.00),
                Color(red: 0.88, green: 0.00, blue: 1.00)
            ]
        case .mintBreeze:
            return [
                Color(red: 0.46, green: 0.93, blue: 0.78),
                Color(red: 0.37, green: 0.87, blue: 0.66),
                Color(red: 0.24, green: 0.86, blue: 0.59)
            ]
        case .lavaBurst:
            return [
                Color(red: 0.99, green: 0.27, blue: 0.42),
                Color(red: 0.25, green: 0.37, blue: 0.98)
            ]
        case .iceCrystal:
            return [
                Color(red: 0.63, green: 0.77, blue: 0.99),
                Color(red: 0.76, green: 0.91, blue: 0.98)
            ]
        case .coralSunset:
            return [
                Color(red: 1.00, green: 0.60, blue: 0.40),
                Color(red: 1.00, green: 0.37, blue: 0.38)
            ]
        case .auroraGlow:
            return [
                Color(red: 0.00, green: 0.96, blue: 0.63),
                Color(red: 0.00, green: 0.85, blue: 0.96)
            ]
        case .forestEmerald:
            return [
                Color(red: 0.07, green: 0.60, blue: 0.56),
                Color(red: 0.22, green: 0.94, blue: 0.49)
            ]
        case .skyMorning:
            return [
                Color(red: 0.31, green: 0.67, blue: 1.00),
                Color(red: 0.00, green: 0.95, blue: 0.99)
            ]
        case .pinkNebula:
            return [
                Color(red: 0.97, green: 0.34, blue: 0.65),
                Color(red: 1.00, green: 0.35, blue: 0.35)
            ]
        case .electricNight:
            return [
                Color(red: 0.10, green: 0.09, blue: 0.33),
                Color(red: 0.26, green: 0.78, blue: 0.67)
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
        case .sunsetAura:
            return [
                Color(red: 1.00, green: 0.46, blue: 0.52),
                Color(red: 1.00, green: 0.80, blue: 0.52)
            ]
        case .oceanDeep:
            return [
                Color(red: 0.23, green: 0.33, blue: 0.70),
                Color(red: 0.00, green: 0.85, blue: 0.92)
            ]
        case .cosmicPurple:
            return [
                Color(red: 0.64, green: 0.10, blue: 1.00),
                Color(red: 0.96, green: 0.36, blue: 1.00)
            ]
        case .mintBreeze:
            return [
                Color(red: 0.51, green: 0.94, blue: 0.80),
                Color(red: 0.29, green: 0.85, blue: 0.63)
            ]
        case .lavaBurst:
            return [
                Color(red: 0.98, green: 0.36, blue: 0.52),
                Color(red: 0.32, green: 0.46, blue: 0.99)
            ]
        case .iceCrystal:
            return [
                Color(red: 0.71, green: 0.84, blue: 0.99),
                Color(red: 0.85, green: 0.94, blue: 0.99)
            ]
        case .coralSunset:
            return [
                Color(red: 1.00, green: 0.63, blue: 0.44),
                Color(red: 1.00, green: 0.40, blue: 0.38)
            ]
        case .auroraGlow:
            return [
                Color(red: 0.05, green: 0.98, blue: 0.69),
                Color(red: 0.00, green: 0.80, blue: 0.86)
            ]
        case .forestEmerald:
            return [
                Color(red: 0.12, green: 0.66, blue: 0.58),
                Color(red: 0.31, green: 0.93, blue: 0.58)
            ]
        case .skyMorning:
            return [
                Color(red: 0.41, green: 0.74, blue: 1.00),
                Color(red: 0.09, green: 0.86, blue: 0.99)
            ]
        case .pinkNebula:
            return [
                Color(red: 0.98, green: 0.45, blue: 0.71),
                Color(red: 1.00, green: 0.45, blue: 0.45)
            ]
        case .electricNight:
            return [
                Color(red: 0.23, green: 0.21, blue: 0.52),
                Color(red: 0.38, green: 0.84, blue: 0.74)
            ]
        }
    }
}
