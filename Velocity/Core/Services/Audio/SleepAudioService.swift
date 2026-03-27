//
//  SleepAudioService.swift
//  Velocity
//

import Foundation

enum SleepAudioEngineState: Equatable {
    case idle
    case playing(trackID: String)
    case paused(trackID: String)
    case failed(message: String)
}

@MainActor
protocol SleepAudioService: AnyObject {
    var state: SleepAudioEngineState { get }
    var volume: Double { get }
    var isLoopEnabled: Bool { get }
    var onStateChange: ((SleepAudioEngineState) -> Void)? { get set }

    func play(resourceName: String, fileExtension: String, trackID: String)
    func pause()
    func stop()
    func setVolume(_ volume: Double)
    func setLoopEnabled(_ isEnabled: Bool)
}

@MainActor
final class NoopSleepAudioService: SleepAudioService {
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
        self.volume = max(0, min(1, volume))
    }

    func setLoopEnabled(_ isEnabled: Bool) {
        isLoopEnabled = isEnabled
    }
}

