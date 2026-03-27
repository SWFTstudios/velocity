//
//  SleepSoundsViewModel.swift
//  Velocity
//

import Foundation

@Observable
@MainActor
final class SleepSoundsViewModel {
    let tracks: [SleepSoundTrack]
    var playbackState: SleepAudioPlaybackState = .idle
    var selectedTrackID: String?
    var volume: Double
    var isLoopEnabled: Bool
    var errorMessage: String?

    private let settingsStore: UserSettingsStore
    private let audioService: SleepAudioService

    init(
        settingsStore: UserSettingsStore,
        audioService: SleepAudioService,
        tracks: [SleepSoundTrack] = SleepSoundsViewModel.defaultTracks
    ) {
        self.settingsStore = settingsStore
        self.audioService = audioService
        self.tracks = tracks

        volume = settingsStore.settings.sleepSoundVolume
        isLoopEnabled = settingsStore.settings.sleepSoundLoopEnabled
        let preferred = settingsStore.settings.preferredSleepSoundID
        if let preferred, tracks.contains(where: { $0.id == preferred }) {
            selectedTrackID = preferred
        } else {
            selectedTrackID = tracks.first?.id
            if preferred != nil {
                settingsStore.setPreferredSleepSoundID(tracks.first?.id)
            }
        }

        audioService.setVolume(volume)
        audioService.setLoopEnabled(isLoopEnabled)
        playbackState = Self.mapEngineState(audioService.state)
        bindAudioState()
    }

    func togglePlay(track: SleepSoundTrack) {
        errorMessage = nil
        selectedTrackID = track.id
        settingsStore.setPreferredSleepSoundID(track.id)

        switch playbackState {
        case let .playing(trackID) where trackID == track.id:
            audioService.pause()
        default:
            audioService.play(
                resourceName: track.resourceName,
                fileExtension: track.fileExtension,
                trackID: track.id
            )
        }
    }

    func stop() {
        audioService.stop()
    }

    func selectTrack(_ track: SleepSoundTrack) {
        selectedTrackID = track.id
        settingsStore.setPreferredSleepSoundID(track.id)
    }

    func setVolume(_ newValue: Double) {
        let clamped = max(0, min(1, newValue))
        volume = clamped
        audioService.setVolume(clamped)
        settingsStore.setSleepSoundVolume(clamped)
    }

    func setLoopEnabled(_ enabled: Bool) {
        isLoopEnabled = enabled
        audioService.setLoopEnabled(enabled)
        settingsStore.setSleepSoundLoopEnabled(enabled)
    }

    func isTrackActive(_ track: SleepSoundTrack) -> Bool {
        playbackState.activeTrackID == track.id
    }

    func isTrackPlaying(_ track: SleepSoundTrack) -> Bool {
        if case let .playing(trackID) = playbackState {
            return trackID == track.id
        }
        return false
    }

    func track(for id: String?) -> SleepSoundTrack? {
        guard let id else { return nil }
        return tracks.first { $0.id == id }
    }

    /// Hero card follows playback when active; otherwise the user’s selected track.
    var heroTrack: SleepSoundTrack? {
        let id = playbackState.activeTrackID ?? selectedTrackID
        return track(for: id)
    }

    var heroStatusLabel: String? {
        switch playbackState {
        case .idle:
            return nil
        case .playing:
            return "Now playing"
        case .paused:
            return "Paused"
        case .failed:
            return nil
        }
    }

    func isTrackPaused(_ track: SleepSoundTrack) -> Bool {
        if case let .paused(trackID) = playbackState {
            return trackID == track.id
        }
        return false
    }

    private func bindAudioState() {
        audioService.onStateChange = { [weak self] newState in
            guard let self else { return }
            playbackState = Self.mapEngineState(newState)
            if case let .failed(message) = playbackState {
                errorMessage = message
            }
        }
    }

    private static func mapEngineState(_ state: SleepAudioEngineState) -> SleepAudioPlaybackState {
        switch state {
        case .idle:
            return .idle
        case let .playing(trackID):
            return .playing(trackID: trackID)
        case let .paused(trackID):
            return .paused(trackID: trackID)
        case let .failed(message):
            return .failed(message: message)
        }
    }
}

extension SleepSoundsViewModel {
    nonisolated static let defaultTracks: [SleepSoundTrack] = [
        SleepSoundTrack(
            id: "white-noise-classic",
            title: "White noise",
            subtitle: "Even energy across frequencies",
            symbolName: "waveform",
            resourceName: "white_noise_classic",
            fileExtension: "wav"
        ),
        SleepSoundTrack(
            id: "pink-noise",
            title: "Pink noise",
            subtitle: "Softer highs, warmer blend",
            symbolName: "waveform.path",
            resourceName: "pink_noise",
            fileExtension: "wav"
        ),
        SleepSoundTrack(
            id: "brown-noise",
            title: "Brown noise",
            subtitle: "Deep, low-frequency emphasis",
            symbolName: "waveform.path.ecg",
            resourceName: "brown_noise",
            fileExtension: "wav"
        ),
    ]
}

