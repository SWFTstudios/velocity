//
//  HttpAlarmCallService.swift
//  Velocity
//

import Foundation

final class HttpAlarmCallService: AlarmCallService {
    private let config: AlarmCallConfig
    private let session: URLSession

    init(config: AlarmCallConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func triggerAlarmCall(_ requestPayload: AlarmCallRequest) async throws -> AlarmCallResult {
        guard let url = URL(string: config.alarmEndpoint) else {
            return AlarmCallResult(status: .failed, callSid: nil, userFacingMessage: "Call endpoint is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let key = config.devApiKey, !key.isEmpty {
            request.setValue(key, forHTTPHeaderField: "x-dev-key")
        }
        request.timeoutInterval = config.requestTimeoutSeconds
        request.httpBody = try JSONEncoder().encode(requestPayload)

        var attempts = 0
        var lastFailureMessage = "Failed to initiate alarm call."

        while attempts <= config.maxRetryCount {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    lastFailureMessage = "Unexpected call response."
                    attempts += 1
                    continue
                }

                let decoded = try? JSONDecoder().decode(AlarmCallResponse.self, from: data)
                if (200 ... 299).contains(http.statusCode), decoded?.ok == true {
                    if decoded?.duplicate == true {
                        return AlarmCallResult(status: .duplicate, callSid: decoded?.callSid, userFacingMessage: "Call already initiated.")
                    }
                    return AlarmCallResult(status: .success, callSid: decoded?.callSid, userFacingMessage: "Wake call is in progress.")
                }

                lastFailureMessage = decoded?.error ?? "Call failed. Please try again."
                attempts += 1
            } catch {
                lastFailureMessage = "Network unavailable. Please retry."
                attempts += 1
            }
        }

        return AlarmCallResult(status: .failed, callSid: nil, userFacingMessage: lastFailureMessage)
    }
}

