//
//  SleepSoundsModels.swift
//  Velocity
//

import Foundation

struct SleepSoundTrack: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    let resourceName: String
    let fileExtension: String
}

enum SleepAudioPlaybackState: Equatable {
    case idle
    case playing(trackID: String)
    case paused(trackID: String)
    case failed(message: String)

    var activeTrackID: String? {
        switch self {
        case let .playing(trackID), let .paused(trackID):
            return trackID
        case .idle, .failed:
            return nil
        }
    }

    var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }
}

