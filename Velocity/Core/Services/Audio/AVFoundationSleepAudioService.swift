//
//  AVFoundationSleepAudioService.swift
//  Velocity
//

import AVFoundation
import Foundation

@MainActor
final class AVFoundationSleepAudioService: NSObject, SleepAudioService {
    var state: SleepAudioEngineState = .idle {
        didSet { onStateChange?(state) }
    }
    var volume: Double = 0.7 {
        didSet { player?.volume = Float(volume) }
    }
    var isLoopEnabled: Bool = true {
        didSet { player?.numberOfLoops = isLoopEnabled ? -1 : 0 }
    }
    var onStateChange: ((SleepAudioEngineState) -> Void)?

    private var player: AVAudioPlayer?
    private var activeTrackID: String?

    func play(resourceName: String, fileExtension: String, trackID: String) {
        do {
            if activeTrackID == trackID, let player {
                player.numberOfLoops = isLoopEnabled ? -1 : 0
                player.volume = Float(volume)
                player.play()
                state = .playing(trackID: trackID)
                return
            }

            guard let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) else {
                state = .failed(message: "Audio file missing: \(resourceName).\(fileExtension)")
                return
            }

            let player = try AVAudioPlayer(contentsOf: url)
            self.player = player
            activeTrackID = trackID
            player.delegate = self
            player.volume = Float(volume)
            player.numberOfLoops = isLoopEnabled ? -1 : 0
            player.prepareToPlay()
            player.play()
            state = .playing(trackID: trackID)
        } catch {
            state = .failed(message: "Unable to play audio track.")
        }
    }

    func pause() {
        guard let player, let activeTrackID else { return }
        player.pause()
        state = .paused(trackID: activeTrackID)
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        activeTrackID = nil
        state = .idle
    }

    func setVolume(_ volume: Double) {
        self.volume = max(0, min(1, volume))
    }

    func setLoopEnabled(_ isEnabled: Bool) {
        isLoopEnabled = isEnabled
    }
}

extension AVFoundationSleepAudioService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if isLoopEnabled {
                player.play()
                return
            }
            activeTrackID = nil
            state = .idle
        }
    }
}

