//
//  SleepSoundsLibraryView.swift
//  Velocity
//

import SwiftUI

struct SleepSoundsLibraryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VelocitySpacing.lg) {
                HStack {
                    Label("Library", systemImage: "chevron.left")
                        .font(VelocityFontStyle.body(14))
                        .foregroundStyle(VelocityColor.onSurfaceVariant)
                    Spacer()
                    Text("Velocity")
                        .font(VelocityFontStyle.title(14))
                        .foregroundStyle(VelocityColor.primary)
                }
                .padding(.horizontal, VelocitySpacing.sm)

                Text("CHAISE & REFLECTION")
                    .font(VelocityFontStyle.label(10))
                    .foregroundStyle(VelocityColor.primary)
                    .tracking(1.0)

                Text("Sonic architecture")
                    .font(VelocityFontStyle.headline(28))
                    .foregroundStyle(VelocityColor.onSurface)

                Text("Design your environment with high-fidelity soundscapes optimized for sleep restoration.")
                    .font(VelocityFontStyle.body(15))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)

                HStack {
                    Text("Nature sounds")
                        .font(VelocityFontStyle.title(18))
                        .foregroundStyle(VelocityColor.onSurface)
                    Spacer()
                    Button("View all") {}
                        .font(VelocityFontStyle.label(11))
                        .foregroundStyle(VelocityColor.primary)
                }

                featuredCard
            }
            .padding(VelocitySpacing.md)
        }
        .background(VelocityColor.surface.ignoresSafeArea())
        .navigationTitle("Sleep sounds")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(uiColor: .systemBackground), for: .navigationBar)
    }

    private var featuredCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [VelocityColor.surfaceContainerHigh, VelocityColor.surfaceContainerLowest],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)
                .overlay {
                    Image(systemName: "cloud.rain.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(VelocityColor.onSurfaceVariant.opacity(0.35))
                }
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(VelocityColor.primary)
                    .frame(width: 4, height: 20)
                Text("Midnight rain")
                    .font(VelocityFontStyle.title(18))
                    .foregroundStyle(VelocityColor.onSurface)
            }
            .padding(VelocitySpacing.md)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Midnight rain soundscape, sample")
    }
}

#Preview {
    NavigationStack {
        SleepSoundsLibraryView()
    }
}
