//
//  VelocityTheme.swift
//  Velocity
//
//  Semantic colors and spacing derived from Stitch "Midnight Calm" (DesignSystem.md).
//

import SwiftUI

enum VelocityColor {
    static let surface = Color(red: 0.067, green: 0.075, blue: 0.110) // #11131c
    static let surfaceContainerLowest = Color(red: 0.047, green: 0.055, blue: 0.090) // #0c0e17
    static let surfaceContainer = Color(red: 0.114, green: 0.122, blue: 0.161) // #1d1f29
    static let surfaceContainerHigh = Color(red: 0.157, green: 0.161, blue: 0.200) // #282933
    static let surfaceContainerHighest = Color(red: 0.196, green: 0.204, blue: 0.243) // #32343e
    static let surfaceBright = Color(red: 0.216, green: 0.224, blue: 0.263) // #373943

    static let primary = Color(red: 1.0, green: 0.729, blue: 0.220) // #ffba38
    static let onPrimaryFixed = Color(red: 0.157, green: 0.098, blue: 0.0) // deep charcoal for on-gradient text
    static let onPrimaryContainer = Color(red: 0.659, green: 0.459, blue: 0.0) // #a87500
    static let secondary = Color(red: 0.729, green: 0.765, blue: 1.0) // #bac3ff

    static let onSurface = Color(red: 0.882, green: 0.882, blue: 0.937) // #e1e1ef
    static let onSurfaceVariant = Color(red: 0.780, green: 0.776, blue: 0.800) // #c7c6cc
    static let onTertiaryContainer = Color(red: 0.455, green: 0.506, blue: 0.533) // #748188

    static let outlineVariantMuted = Color(red: 0.275, green: 0.275, blue: 0.294).opacity(0.2) // #46464b @ 20%
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
