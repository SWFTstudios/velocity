//
//  TripHistoryStore.swift
//  Velocity
//

import Foundation
import Observation

@Observable
@MainActor
final class TripHistoryStore {
    private static let storageKey = "Velocity.TripHistoryStore.records.v1"
    private(set) var records: [TripRecord] = []

    init() {
        self.records = Self.load()
    }

    func append(_ record: TripRecord) {
        records.insert(record, at: 0)
        persist()
    }

    func clearAll() {
        records = []
        persist()
    }

    func reloadFromPersistence() {
        records = Self.load()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            // Keep failure silent for MVP and avoid user-facing disruption.
        }
    }

    private static func load() -> [TripRecord] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([TripRecord].self, from: data)
        } catch {
            return []
        }
    }
}

