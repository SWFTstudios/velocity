//
//  TripProgressViewModel.swift
//  Velocity
//

import Foundation
import Observation

@MainActor
@Observable
final class TripProgressViewModel {
    private(set) var progressFraction: Double = 0

    private var baselineStartDistanceMeters: Double?
    private var baselineStartETASeconds: TimeInterval?

    func resetBaselines() {
        baselineStartDistanceMeters = nil
        baselineStartETASeconds = nil
        progressFraction = 0
    }

    func updateProgress(for tripStore: TripSessionStore) {
        let status = tripStore.session.status
        if status == .idle {
            resetBaselines()
            return
        }

        // Wake must be forced to 100% to sync with the alarm trigger.
        if status == .waking {
            progressFraction = 1
            return
        }

        switch tripStore.session.threshold {
        case let .distanceKilometers(km):
            let thresholdMeters = km * 1000
            guard let current = tripStore.session.activeDistanceMeters else { return }
            if baselineStartDistanceMeters == nil {
                baselineStartDistanceMeters = current
            }
            guard let start = baselineStartDistanceMeters else { return }

            if start <= thresholdMeters {
                progressFraction = 1
                return
            }

            let denom = start - thresholdMeters
            guard denom > 0 else {
                progressFraction = 1
                return
            }

            let raw = (start - current) / denom
            progressFraction = Self.clamp01(raw)

        case let .timeBeforeArrival(thresholdSeconds):
            guard let currentETA = tripStore.session.activeETASeconds else { return }
            if baselineStartETASeconds == nil {
                baselineStartETASeconds = currentETA
            }
            guard let start = baselineStartETASeconds else { return }

            if start <= thresholdSeconds {
                progressFraction = 1
                return
            }

            let denom = start - thresholdSeconds
            guard denom > 0 else {
                progressFraction = 1
                return
            }

            let raw = (start - currentETA) / denom
            progressFraction = Self.clamp01(raw)
        }
    }

    private static func clamp01(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}

