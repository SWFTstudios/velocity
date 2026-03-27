//
//  VelocityTheme.swift
//  Velocity
//
//  Semantic colors and spacing derived from Stitch "Midnight Calm" (DesignSystem.md).
//

import SwiftUI

struct VelocityPalette {
    let surface: Color
    let surfaceContainerLowest: Color
    let surfaceContainer: Color
    let surfaceContainerHigh: Color
    let surfaceContainerHighest: Color
    let surfaceBright: Color
    let primary: Color
    let onPrimaryFixed: Color
    let onPrimaryContainer: Color
    let secondary: Color
    let onSurface: Color
    let onSurfaceVariant: Color
    let onTertiaryContainer: Color
    let outlineVariantMuted: Color
}

enum VelocityColor {
    private static func palette(for colorway: AppColorway) -> VelocityPalette {
        switch colorway {
        case .midnightCalm:
            return VelocityPalette(
                surface: Color(red: 0.067, green: 0.075, blue: 0.110), // #11131c
                surfaceContainerLowest: Color(red: 0.047, green: 0.055, blue: 0.090), // #0c0e17
                surfaceContainer: Color(red: 0.114, green: 0.122, blue: 0.161), // #1d1f29
                surfaceContainerHigh: Color(red: 0.157, green: 0.161, blue: 0.200), // #282933
                surfaceContainerHighest: Color(red: 0.196, green: 0.204, blue: 0.243), // #32343e
                surfaceBright: Color(red: 0.216, green: 0.224, blue: 0.263), // #373943
                primary: Color(red: 1.0, green: 0.729, blue: 0.220), // #ffba38
                onPrimaryFixed: Color(red: 0.157, green: 0.098, blue: 0.0),
                onPrimaryContainer: Color(red: 0.659, green: 0.459, blue: 0.0), // #a87500
                secondary: Color(red: 0.729, green: 0.765, blue: 1.0), // #bac3ff
                onSurface: Color(red: 0.882, green: 0.882, blue: 0.937), // #e1e1ef
                onSurfaceVariant: Color(red: 0.780, green: 0.776, blue: 0.800), // #c7c6cc
                onTertiaryContainer: Color(red: 0.455, green: 0.506, blue: 0.533), // #748188
                outlineVariantMuted: Color(red: 0.275, green: 0.275, blue: 0.294).opacity(0.2) // #46464b @ 20%
            )
        case .kineticHorizon:
            return VelocityPalette(
                surface: Color(red: 0.024, green: 0.055, blue: 0.125), // #060e20
                surfaceContainerLowest: Color(red: 0.027, green: 0.063, blue: 0.133), // deep base fallback
                surfaceContainer: Color(red: 0.059, green: 0.098, blue: 0.188), // #0f1930
                surfaceContainerHigh: Color(red: 0.082, green: 0.129, blue: 0.235), // elevated intermediary
                surfaceContainerHighest: Color(red: 0.098, green: 0.145, blue: 0.251), // #192540
                surfaceBright: Color(red: 0.161, green: 0.224, blue: 0.363), // brighter HUD surface
                primary: Color(red: 0.506, green: 0.925, blue: 1.0), // #81ecff
                onPrimaryFixed: Color(red: 0.0, green: 0.341, blue: 0.384), // #005762
                onPrimaryContainer: Color(red: 0.0, green: 0.890, blue: 0.992), // #00e3fd
                secondary: Color(red: 1.0, green: 0.451, blue: 0.290), // #ff734a
                onSurface: Color(red: 0.933, green: 0.957, blue: 1.0), // light text on deep blue
                onSurfaceVariant: Color(red: 0.639, green: 0.667, blue: 0.769), // #a3aac4
                onTertiaryContainer: Color(red: 0.761, green: 1.0, blue: 0.600), // #c2ff99
                outlineVariantMuted: Color(red: 0.251, green: 0.282, blue: 0.365).opacity(0.15) // #40485d @ 15%
            )
        }
    }

    static var currentPalette: VelocityPalette {
        palette(for: UserSettingsStore.currentColorway())
    }

    static var surface: Color { currentPalette.surface }
    static var surfaceContainerLowest: Color { currentPalette.surfaceContainerLowest }
    static var surfaceContainer: Color { currentPalette.surfaceContainer }
    static var surfaceContainerHigh: Color { currentPalette.surfaceContainerHigh }
    static var surfaceContainerHighest: Color { currentPalette.surfaceContainerHighest }
    static var surfaceBright: Color { currentPalette.surfaceBright }
    static var primary: Color { currentPalette.primary }
    static var onPrimaryFixed: Color { currentPalette.onPrimaryFixed }
    static var onPrimaryContainer: Color { currentPalette.onPrimaryContainer }
    static var secondary: Color { currentPalette.secondary }
    static var onSurface: Color { currentPalette.onSurface }
    static var onSurfaceVariant: Color { currentPalette.onSurfaceVariant }
    static var onTertiaryContainer: Color { currentPalette.onTertiaryContainer }
    static var outlineVariantMuted: Color { currentPalette.outlineVariantMuted }
}

enum VelocitySpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum VelocityRadius {
    static let card: CGFloat = 16
    static let control: CGFloat = 14
    static let pill: CGFloat = 9999
}

enum VelocityFontStyle {
    /// Lexend in design spec; use rounded system until a font package is added.
    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }

    static func title(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func headline(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

extension LinearGradient {
    static var velocityPrimaryCTA: LinearGradient {
        LinearGradient(
            colors: [VelocityColor.primary, VelocityColor.onPrimaryContainer],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct VelocityPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(VelocityFontStyle.title(16))
            .foregroundStyle(VelocityColor.onPrimaryFixed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: VelocityRadius.control, style: .continuous)
                    .fill(LinearGradient.velocityPrimaryCTA)
                    .opacity(configuration.isPressed ? 0.85 : 1)
            )
    }
}
