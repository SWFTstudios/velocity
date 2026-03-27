//
//  AlarmCallConfig.swift
//  Velocity
//

import Foundation

struct AlarmCallConfig: Codable, Sendable {
    let alarmEndpoint: String
    let devApiKey: String?
    let requestTimeoutSeconds: Double
    let maxRetryCount: Int
    let defaultToPhoneNumber: String
    let twilioFromPhoneSid: String?

    static let localFilename = "AlarmCallConfig.local"

    static func load() -> AlarmCallConfig? {
        if let fromBundle = loadFromBundle() {
            return fromBundle
        }
        return nil
    }

    private static func loadFromBundle() -> AlarmCallConfig? {
        guard let url = Bundle.main.url(forResource: localFilename, withExtension: "json") else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(AlarmCallConfig.self, from: data)
    }
}

