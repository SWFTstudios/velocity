//
//  HistoryViewModel.swift
//  Velocity
//

import Foundation
import Observation

@Observable
@MainActor
final class HistoryViewModel {
    private let historyStore: TripHistoryStore

    init(historyStore: TripHistoryStore) {
        self.historyStore = historyStore
    }

    var records: [TripRecord] {
        historyStore.records
    }

    var hasRecords: Bool {
        !records.isEmpty
    }

    func clearAll() {
        historyStore.clearAll()
    }
}

