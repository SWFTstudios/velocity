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

    var mapSymbolName: String {
        switch self {
        case .train: "train.side.front.car"
        case .car: "car.fill"
        case .bus: "bus.fill"
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
    case waking
}

struct CoordinatePoint: Equatable, Codable, Sendable {
    var latitude: Double
    var longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum WakeTriggerReason: String, Codable, Sendable {
    case distanceThreshold
    case timeThreshold
    case manual
}

enum AlarmCallState: String, Codable, Sendable {
    case idle
    case calling
    case success
    case failed
    case skippedNotConfigured
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
    var startedAt: Date?
    var endedAt: Date?
    var wakeTriggeredAt: Date?
    var wakeTriggerReason: WakeTriggerReason?
    var activeDistanceMeters: Double?
    var activeETASeconds: TimeInterval?
    var activeRouteCoordinates: [CoordinatePoint]
    var originCoordinate: CoordinatePoint?
    var alarmCallState: AlarmCallState
    var lastAlarmCallErrorMessage: String?
    var lastAlarmCallAt: Date?
    var alarmCallIdempotencyKey: String?
    var alarmCallSid: String?

    nonisolated static func empty(id: UUID = UUID()) -> TripSession {
        let defaultWakeKm = UserSettingsStore.currentDefaultWakeRadiusKilometers()
        let wakeRadiusText: String = {
            switch UserSettingsStore.currentMeasurementUnit() {
            case .kilometers:
                let rounded = (defaultWakeKm * 10).rounded() / 10
                return "Wake at \(rounded) km radius"
            case .miles:
                let miles = defaultWakeKm * 0.621371
                let rounded = (miles * 10).rounded() / 10
                return "Wake at \(rounded) mi radius"
            }
        }()
        let session = TripSession(
            id: id,
            destination: nil,
            threshold: .distanceKilometers(defaultWakeKm),
            mode: .train,
            status: .idle,
            journeyTitle: "Your journey",
            etaDisplay: "—:—",
            distanceDisplay: "—",
            phasesDisplay: "—",
            nextStopName: "Destination",
            onTrackLabel: "ON TRACK",
            wakeRadiusBadgeText: wakeRadiusText,
            currentLocationLabel: "—",
            minutesToDestination: 12,
            napEstimateMinutes: nil,
            startedAt: nil,
            endedAt: nil,
            wakeTriggeredAt: nil,
            wakeTriggerReason: nil,
            activeDistanceMeters: nil,
            activeETASeconds: nil,
            activeRouteCoordinates: [],
            originCoordinate: nil,
            alarmCallState: .idle,
            lastAlarmCallErrorMessage: nil,
            lastAlarmCallAt: nil,
            alarmCallIdempotencyKey: nil,
            alarmCallSid: nil
        )
        return session
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
            switch UserSettingsStore.currentMeasurementUnit() {
            case .kilometers:
                let rounded = (km * 10).rounded() / 10
                return "Wake at \(rounded) km radius"
            case .miles:
                let miles = km * 0.621371
                let rounded = (miles * 10).rounded() / 10
                return "Wake at \(rounded) mi radius"
            }
        case let .timeBeforeArrival(seconds):
            let minutes = Int(seconds / 60)
            return "Wake \(minutes) min before arrival"
        }
    }
}

struct TripRecord: Identifiable, Equatable, Codable, Sendable {
    var id: UUID
    var startedAt: Date
    var endedAt: Date
    var mode: TransitMode
    var threshold: WakeThreshold
    var destination: CommuteDestination
    var originCoordinate: CoordinatePoint?
    var finalDistanceMeters: Double?
    var finalETASeconds: TimeInterval?
    var wakeTriggeredAt: Date?
    var wakeTriggerReason: WakeTriggerReason?
    var wasAwakened: Bool
    var routeCoordinates: [CoordinatePoint]
    var alarmCallState: AlarmCallState
    var alarmCallSid: String?
    var alarmCallErrorMessage: String?

    var durationSeconds: TimeInterval {
        endedAt.timeIntervalSince(startedAt)
    }
}

struct UserSettings: Equatable, Codable {
    var notificationsEnabled: Bool
    var quietModeEnabled: Bool
    var theme: AppTheme
    var colorway: AppColorway
    var measurementUnit: MeasurementUnit
    var preferredSleepSoundID: String?
    var sleepSoundVolume: Double
    var sleepSoundLoopEnabled: Bool
    /// Default alarm radius applied when starting a new trip in `.planning`.
    /// Stored in kilometers to avoid unit-coupling.
    var defaultWakeRadiusKilometers: Double

    static let `default` = UserSettings(
        notificationsEnabled: true,
        quietModeEnabled: false,
        theme: .system,
        colorway: .midnightCalm,
        measurementUnit: .kilometers,
        preferredSleepSoundID: nil,
        sleepSoundVolume: 0.7,
        sleepSoundLoopEnabled: true,
        defaultWakeRadiusKilometers: 0.3 * 1.609344 // 0.3 mi
    )

    init(
        notificationsEnabled: Bool,
        quietModeEnabled: Bool,
        theme: AppTheme,
        colorway: AppColorway,
        measurementUnit: MeasurementUnit,
        preferredSleepSoundID: String?,
        sleepSoundVolume: Double,
        sleepSoundLoopEnabled: Bool,
        defaultWakeRadiusKilometers: Double
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.quietModeEnabled = quietModeEnabled
        self.theme = theme
        self.colorway = colorway
        self.measurementUnit = measurementUnit
        self.preferredSleepSoundID = preferredSleepSoundID
        self.sleepSoundVolume = sleepSoundVolume
        self.sleepSoundLoopEnabled = sleepSoundLoopEnabled
        self.defaultWakeRadiusKilometers = defaultWakeRadiusKilometers
    }

    private enum CodingKeys: String, CodingKey {
        case notificationsEnabled
        case quietModeEnabled
        case theme
        case colorway
        case measurementUnit
        case preferredSleepSoundID
        case sleepSoundVolume
        case sleepSoundLoopEnabled
        case defaultWakeRadiusKilometers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notificationsEnabled = try container.decode(Bool.self, forKey: .notificationsEnabled)
        quietModeEnabled = try container.decode(Bool.self, forKey: .quietModeEnabled)
        theme = try container.decode(AppTheme.self, forKey: .theme)
        colorway = try container.decodeIfPresent(AppColorway.self, forKey: .colorway) ?? .midnightCalm
        measurementUnit = try container.decodeIfPresent(MeasurementUnit.self, forKey: .measurementUnit) ?? .kilometers
        preferredSleepSoundID = try container.decodeIfPresent(String.self, forKey: .preferredSleepSoundID)
        sleepSoundVolume = try container.decodeIfPresent(Double.self, forKey: .sleepSoundVolume) ?? 0.7
        sleepSoundLoopEnabled = try container.decodeIfPresent(Bool.self, forKey: .sleepSoundLoopEnabled) ?? true
        defaultWakeRadiusKilometers = try container.decodeIfPresent(Double.self, forKey: .defaultWakeRadiusKilometers) ?? (0.3 * 1.609344)
    }
}

enum MeasurementUnit: String, CaseIterable, Codable {
    case kilometers
    case miles

    var displayName: String {
        switch self {
        case .kilometers: "Kilometers"
        case .miles: "Miles"
        }
    }

    var distanceSuffix: String {
        switch self {
        case .kilometers: "km"
        case .miles: "mi"
        }
    }
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

enum AppColorway: String, CaseIterable, Codable {
    case midnightCalm
    case kineticHorizon

    var displayName: String {
        switch self {
        case .midnightCalm: "Midnight Calm"
        case .kineticHorizon: "Kinetic Horizon"
        }
    }
}
