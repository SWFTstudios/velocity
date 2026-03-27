//
//  AlarmCallService.swift
//  Velocity
//

import Foundation

protocol AlarmCallService: AnyObject {
    func triggerAlarmCall(_ request: AlarmCallRequest) async throws -> AlarmCallResult
}

final class NoopAlarmCallService: AlarmCallService {
    func triggerAlarmCall(_ request: AlarmCallRequest) async throws -> AlarmCallResult {
        AlarmCallResult(
            status: .failed,
            callSid: nil,
            userFacingMessage: "Call service not configured."
        )
    }
}

#if DEBUG
final class MockAlarmCallService: AlarmCallService {
    var result: AlarmCallResult

    init(result: AlarmCallResult = AlarmCallResult(status: .success, callSid: "CA_MOCK", userFacingMessage: "Call initiated.")) {
        self.result = result
    }

    func triggerAlarmCall(_ request: AlarmCallRequest) async throws -> AlarmCallResult {
        result
    }
}
#endif

