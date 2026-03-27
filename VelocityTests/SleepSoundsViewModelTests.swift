import XCTest
@testable import Velocity

@MainActor
final class SleepSoundsViewModelTests: XCTestCase {
    func testTogglePlayStartsThenPausesSameTrack() {
        let settings = UserSettingsStore(settings: .default)
        let service = MockSleepAudioService()
        let vm = SleepSoundsViewModel(settingsStore: settings, audioService: service)
        let track = vm.tracks[0]

        vm.togglePlay(track: track)
        XCTAssertEqual(vm.playbackState, .playing(trackID: track.id))

        vm.togglePlay(track: track)
        XCTAssertEqual(vm.playbackState, .paused(trackID: track.id))
    }

    func testSwitchTrackStartsNewTrack() {
        let settings = UserSettingsStore(settings: .default)
        let service = MockSleepAudioService()
        let vm = SleepSoundsViewModel(settingsStore: settings, audioService: service)

        let first = vm.tracks[0]
        let second = vm.tracks[1]

        vm.togglePlay(track: first)
        XCTAssertEqual(vm.playbackState, .playing(trackID: first.id))

        vm.togglePlay(track: second)
        XCTAssertEqual(vm.playbackState, .playing(trackID: second.id))
        XCTAssertEqual(vm.selectedTrackID, second.id)
    }

    func testVolumeAndLoopPersistToSettings() {
        let settings = UserSettingsStore(settings: .default)
        let service = MockSleepAudioService()
        let vm = SleepSoundsViewModel(settingsStore: settings, audioService: service)

        vm.setVolume(0.33)
        vm.setLoopEnabled(false)

        XCTAssertEqual(settings.settings.sleepSoundVolume, 0.33, accuracy: 0.001)
        XCTAssertFalse(settings.settings.sleepSoundLoopEnabled)
        XCTAssertEqual(service.volume, 0.33, accuracy: 0.001)
        XCTAssertFalse(service.isLoopEnabled)
    }

    func testPreferredTrackRestoresFromSettings() {
        var initial = UserSettings.default
        initial.preferredSleepSoundID = "brown-noise"
        let settings = UserSettingsStore(settings: initial)
        let service = MockSleepAudioService()
        let vm = SleepSoundsViewModel(settingsStore: settings, audioService: service)

        XCTAssertEqual(vm.selectedTrackID, "brown-noise")
    }

    func testStalePreferredSoundIDFallsBackToFirstTrack() {
        var initial = UserSettings.default
        initial.preferredSleepSoundID = "legacy-removed-track"
        let settings = UserSettingsStore(settings: initial)
        let service = MockSleepAudioService()
        let vm = SleepSoundsViewModel(settingsStore: settings, audioService: service)

        XCTAssertEqual(vm.selectedTrackID, vm.tracks.first?.id)
        XCTAssertEqual(settings.settings.preferredSleepSoundID, vm.tracks.first?.id)
    }
}

@MainActor
private final class MockSleepAudioService: SleepAudioService {
    var state: SleepAudioEngineState = .idle {
        didSet { onStateChange?(state) }
    }
    var volume: Double = 0.7
    var isLoopEnabled: Bool = true
    var onStateChange: ((SleepAudioEngineState) -> Void)?

    func play(resourceName _: String, fileExtension _: String, trackID: String) {
        state = .playing(trackID: trackID)
    }

    func pause() {
        if case let .playing(trackID) = state {
            state = .paused(trackID: trackID)
        }
    }

    func stop() {
        state = .idle
    }

    func setVolume(_ volume: Double) {
        self.volume = volume
    }

    func setLoopEnabled(_ isEnabled: Bool) {
        isLoopEnabled = isEnabled
    }
}

