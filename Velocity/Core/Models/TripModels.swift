//
//  TripModels.swift
//  Velocity
//

import CoreLocation
import Foundation

enum TransitMode: String, CaseIterable, Identifiable, Codable {
    case train
    case car
    case bus

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .train: "Train"
        case .car: "Car"
        case .bus: "Bus"
        }
    }
}

enum WakeThreshold: Equatable, Codable {
    case distanceKilometers(Double)
    case timeBeforeArrival(TimeInterval)

    var distanceKilometersValue: Double? {
        if case let .distanceKilometers(km) = self { return km }
        return nil
    }

    var timeBeforeArrivalValue: TimeInterval? {
        if case let .timeBeforeArrival(t) = self { return t }
        return nil
    }
}

struct CommuteDestination: Equatable, Codable {
    var title: String
    var subtitle: String
    var latitude: Double?
    var longitude: Double?

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

enum TripStatus: String, Codable {
    case idle
    case planning
    case active
    case paused
}

struct TripSession: Identifiable, Equatable, Codable {
    var id: UUID
    var destination: CommuteDestination?
    var threshold: WakeThreshold
    var mode: TransitMode
    var status: TripStatus
    /// Display strings until routing services exist.
    var journeyTitle: String
    var etaDisplay: String
    var distanceDisplay: String
    var phasesDisplay: String
    var nextStopName: String
    var onTrackLabel: String
    var wakeRadiusBadgeText: String
    var currentLocationLabel: String
    var minutesToDestination: Int
    /// Stub nap window from transit mode until routing exists.
    var napEstimateMinutes: Int?

    nonisolated static func empty(id: UUID = UUID()) -> TripSession {
        TripSession(
            id: id,
            destination: nil,
            threshold: .distanceKilometers(10.5),
            mode: .train,
            status: .idle,
            journeyTitle: "Your journey",
            etaDisplay: "—:—",
            distanceDisplay: "—",
            phasesDisplay: "—",
            nextStopName: "Destination",
            onTrackLabel: "ON TRACK",
            wakeRadiusBadgeText: "Wake at 10 km radius",
            currentLocationLabel: "—",
            minutesToDestination: 12,
            napEstimateMinutes: nil
        )
    }

    mutating func applySamplePlanningData() {
        journeyTitle = "Moonlight Drifting"
        etaDisplay = "23:45"
        phasesDisplay = "4 Cycles"
        nextStopName = destination?.title ?? "Destination"
        wakeRadiusBadgeText = wakeBadgeText()
    }

    func wakeBadgeText() -> String {
        switch threshold {
        case let .distanceKilometers(km):
            let rounded = (km * 10).rounded() / 10
            return "Wake at \(rounded) km radius"
        case let .timeBeforeArrival(seconds):
            let minutes = Int(seconds / 60)
            return "Wake \(minutes) min before arrival"
        }
    }
}

struct UserSettings: Equatable, Codable {
    var notificationsEnabled: Bool
    var quietModeEnabled: Bool
    var theme: AppTheme

    static let `default` = UserSettings(
        notificationsEnabled: true,
        quietModeEnabled: false,
        theme: .system
    )
}

enum AppTheme: String, CaseIterable, Codable {
    case system
    case light
    case darkOnly

    var displayName: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .darkOnly: "Midnight Calm"
        }
    }
}
