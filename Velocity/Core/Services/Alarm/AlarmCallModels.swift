//
//  AlarmCallModels.swift
//  Velocity
//

import Foundation

enum AlarmWakeReason: String, Codable, Sendable {
    case distanceThreshold
    case timeThreshold
    case manual
}

struct AlarmCallRequest: Codable, Sendable {
    let tripId: String
    let to: String
    let wakeReason: AlarmWakeReason
    let idempotencyKey: String
    let message: String?
    let destinationTitle: String?
    let destinationSubtitle: String?
    let etaDisplay: String?
    let distanceDisplay: String?
    let timestamp: String
}

enum AlarmCallResultStatus: String, Codable, Sendable {
    case success
    case duplicate
    case failed
}

struct AlarmCallResult: Sendable {
    let status: AlarmCallResultStatus
    let callSid: String?
    let userFacingMessage: String
}

struct AlarmCallResponse: Codable, Sendable {
    let ok: Bool
    let duplicate: Bool?
    let callSid: String?
    let error: String?
    let code: String?
}

