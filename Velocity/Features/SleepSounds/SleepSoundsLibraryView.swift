//
//  SleepSoundsLibraryView.swift
//  Velocity
//

import SwiftUI

struct SleepSoundsLibraryView: View {
    @Bindable var viewModel: SleepSoundsViewModel

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
                    Text("White noise")
                        .font(VelocityFontStyle.title(18))
                        .foregroundStyle(VelocityColor.onSurface)
                    Spacer()
                    if viewModel.playbackState != .idle {
                        Button("Stop") { viewModel.stop() }
                            .font(VelocityFontStyle.label(11))
                            .foregroundStyle(VelocityColor.primary)
                    }
                }

                featuredCard
                playbackControls
                trackList
            }
            .padding(VelocitySpacing.md)
        }
        .background(VelocityColor.surface.ignoresSafeArea())
        .navigationTitle("Sleep sounds")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(VelocityColor.surface, for: .navigationBar)
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
                    Image(systemName: viewModel.heroTrack?.symbolName ?? "waveform")
                        .font(.system(size: 64))
                        .foregroundStyle(VelocityColor.onSurfaceVariant.opacity(0.35))
                }
            VStack(alignment: .leading, spacing: 4) {
                if let status = viewModel.heroStatusLabel {
                    Text(status.uppercased())
                        .font(VelocityFontStyle.label(10))
                        .foregroundStyle(VelocityColor.primary)
                }
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(VelocityColor.primary)
                        .frame(width: 4, height: 20)
                    Text(viewModel.heroTrack?.title ?? "Choose a sound")
                        .font(VelocityFontStyle.title(18))
                        .foregroundStyle(VelocityColor.onSurface)
                }
                if let subtitle = viewModel.heroTrack?.subtitle {
                    Text(subtitle)
                        .font(VelocityFontStyle.body(12))
                        .foregroundStyle(VelocityColor.onSurfaceVariant)
                        .padding(.leading, 12)
                }
            }
            .padding(VelocitySpacing.md)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(featuredCardAccessibilityLabel)
    }

    private var featuredCardAccessibilityLabel: String {
        if let status = viewModel.heroStatusLabel, let title = viewModel.heroTrack?.title {
            return "\(status): \(title)"
        }
        if let title = viewModel.heroTrack?.title {
            return "Selected sound: \(title)"
        }
        return "Choose a sleep sound"
    }

    private var playbackControls: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.md) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(VelocityFontStyle.body(13))
                    .foregroundStyle(VelocityColor.secondary)
            }

            HStack {
                Text("Volume")
                    .font(VelocityFontStyle.body(14))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                Slider(
                    value: Binding(
                        get: { viewModel.volume },
                        set: { viewModel.setVolume($0) }
                    ),
                    in: 0 ... 1
                )
                .tint(VelocityColor.primary)
            }

            Toggle(
                isOn: Binding(
                    get: { viewModel.isLoopEnabled },
                    set: { viewModel.setLoopEnabled($0) }
                )
            ) {
                Text("Loop active sound")
                    .font(VelocityFontStyle.body(14))
                    .foregroundStyle(VelocityColor.onSurface)
            }
            .tint(VelocityColor.primary)
        }
        .padding(VelocitySpacing.md)
        .background(VelocityColor.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))
    }

    private var trackList: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            ForEach(viewModel.tracks) { track in
                HStack(spacing: VelocitySpacing.md) {
                    Image(systemName: track.symbolName)
                        .font(.title3)
                        .foregroundStyle(viewModel.isTrackActive(track) ? VelocityColor.primary : VelocityColor.onSurfaceVariant)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(VelocityFontStyle.title(15))
                            .foregroundStyle(VelocityColor.onSurface)
                        Text(track.subtitle)
                            .font(VelocityFontStyle.body(12))
                            .foregroundStyle(VelocityColor.onSurfaceVariant)
                    }
                    Spacer()

                    if viewModel.isTrackPlaying(track) {
                        Text("NOW")
                            .font(VelocityFontStyle.label(10))
                            .foregroundStyle(VelocityColor.primary)
                    } else if viewModel.isTrackPaused(track) {
                        Text("PAUSED")
                            .font(VelocityFontStyle.label(10))
                            .foregroundStyle(VelocityColor.onSurfaceVariant)
                    }

                    Button {
                        viewModel.togglePlay(track: track)
                    } label: {
                        Image(systemName: viewModel.isTrackPlaying(track) ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(VelocityColor.onPrimaryFixed)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(LinearGradient.velocityPrimaryCTA))
                    }
                    .accessibilityLabel(viewModel.isTrackPlaying(track) ? "Pause \(track.title)" : "Play \(track.title)")
                }
                .padding(.vertical, 8)
                .padding(.horizontal, VelocitySpacing.sm)
                .background(
                    viewModel.isTrackActive(track)
                        ? VelocityColor.surfaceContainerHighest
                        : VelocityColor.surfaceContainerLowest
                )
                .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.control, style: .continuous))
            }
        }
    }
}

#Preview {
    NavigationStack {
        let settings = UserSettingsStore()
        SleepSoundsLibraryView(
            viewModel: SleepSoundsViewModel(
                settingsStore: settings,
                audioService: NoopSleepAudioService()
            )
        )
    }
}
