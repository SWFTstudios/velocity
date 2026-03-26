//
//  SearchService.swift
//  Velocity
//
//  Autocomplete via MKLocalSearchCompleter. Query updates are debounced so
//  we do not hit MapKit on every keystroke (battery + rate limits).
//

import Foundation
import MapKit

@MainActor
final class SearchService: NSObject, SearchProviding, SearchCompletionPublishing, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()
    private var debounceTask: Task<Void, Never>?
    private var rawCompletions: [MKLocalSearchCompletion] = []

    private(set) var completions: [SearchCompletionModel] = []
    var onCompletionsUpdated: (() -> Void)?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func setQueryFragment(_ fragment: String) {
        debounceTask?.cancel()
        let trimmed = fragment.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            completer.queryFragment = ""
            rawCompletions = []
            completions = []
            onCompletionsUpdated?()
            return
        }
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled, let self else { return }
            self.completer.queryFragment = trimmed
        }
    }

    func resolveCompletion(_ model: SearchCompletionModel) async throws -> PlaceResult {
        guard let raw = rawCompletions.first(where: { $0.title == model.title && $0.subtitle == model.subtitle }) else {
            throw SearchResolutionError.noMatchingCompletion
        }
        let request = MKLocalSearch.Request(completion: raw)
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        guard let item = response.mapItems.first else {
            throw SearchResolutionError.noResults
        }
        let pm = item.placemark
        let title = pm.name ?? model.title
        let subtitle = Self.formatPlacemark(pm, fallback: model.subtitle)
        return PlaceResult(title: title, subtitle: subtitle, coordinate: pm.coordinate)
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let raw = completer.results
        let models = raw.map { SearchCompletionModel(title: $0.title, subtitle: $0.subtitle) }
        Task { @MainActor in
            self.rawCompletions = raw
            self.completions = models
            self.onCompletionsUpdated?()
        }
    }

    nonisolated func completerDidFail(_ completer: MKLocalSearchCompleter, withError error: Error) {
        Task { @MainActor in
            self.rawCompletions = []
            self.completions = []
            self.onCompletionsUpdated?()
        }
    }

    enum SearchResolutionError: Error {
        case noMatchingCompletion
        case noResults
    }

    private static func formatPlacemark(_ pm: MKPlacemark, fallback: String) -> String {
        if let thoroughfare = pm.thoroughfare, let locality = pm.locality {
            return "\(thoroughfare), \(locality)"
        }
        if let locality = pm.locality, let country = pm.country {
            return "\(locality), \(country)"
        }
        return fallback
    }
}
