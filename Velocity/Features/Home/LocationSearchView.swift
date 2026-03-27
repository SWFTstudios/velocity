//
//  LocationSearchView.swift
//  Velocity
//

import SwiftUI

/// Full-screen search UI for selecting a destination.
/// Selecting a result sets the destination via `MapViewModel` and dismisses this modal.
struct LocationSearchView: View {
    @Bindable var tripStore: TripSessionStore
    @Bindable var settingsStore: UserSettingsStore
    @Bindable var mapViewModel: MapViewModel

    var onDismiss: (() -> Void)?

    @FocusState private var queryFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                VStack(spacing: VelocitySpacing.sm) {
                    searchField

                    if mapViewModel.showsSearchSuggestions, !mapViewModel.searchCompletions.isEmpty {
                        suggestionsList
                    } else if mapViewModel.searchText.isEmpty {
                        emptyState
                    } else {
                        noResultsState
                    }
                }
                .padding(.horizontal, VelocitySpacing.md)
                .padding(.top, VelocitySpacing.md)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(VelocityColor.surface.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                // If we already have a prefilled query, sync the completer so results show immediately.
                if !mapViewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    mapViewModel.syncSearchQuery(mapViewModel.searchText)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Search")
                .font(VelocityFontStyle.title(18))
                .foregroundStyle(VelocityColor.onSurface)

            Spacer()

            Button {
                onDismiss?()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Dismiss search")
        }
        .padding(.horizontal, VelocitySpacing.md)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var searchField: some View {
        HStack(spacing: VelocitySpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(VelocityColor.onSurfaceVariant)

            TextField("Search for a destination", text: $mapViewModel.searchText)
                .foregroundStyle(VelocityColor.onSurface)
                .font(VelocityFontStyle.body())
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.words)
                .focused($queryFocused)
                .onChange(of: mapViewModel.searchText) { _, newValue in
                    mapViewModel.syncSearchQuery(newValue)
                    mapViewModel.showsSearchSuggestions = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                }

            if !mapViewModel.searchText.isEmpty {
                Button {
                    mapViewModel.syncSearchQuery("")
                    mapViewModel.showsSearchSuggestions = false
                    mapViewModel.clearDestination()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(VelocityColor.onSurfaceVariant)
                        .font(.system(size: 18))
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, VelocitySpacing.md)
        .padding(.vertical, 12)
        .background(VelocityColor.surfaceContainerLowest)
        .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.control, style: .continuous))
    }

    private var suggestionsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(mapViewModel.searchCompletions) { item in
                    Button {
                        mapViewModel.selectSearchCompletion(item)
                        onDismiss?()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(VelocityFontStyle.body())
                                .foregroundStyle(VelocityColor.onSurface)
                            if !item.subtitle.isEmpty {
                                Text(item.subtitle)
                                    .font(VelocityFontStyle.body(12))
                                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .padding(.horizontal, VelocitySpacing.md)
                    }
                    Divider().opacity(0.3)
                }
            }
        }
        .padding(.top, VelocitySpacing.sm)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type a destination to begin.")
                .font(VelocityFontStyle.body(14))
                .foregroundStyle(VelocityColor.onSurfaceVariant)
        }
        .padding(.top, VelocitySpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var noResultsState: some View {
        Text("No results.")
            .font(VelocityFontStyle.body(14))
            .foregroundStyle(VelocityColor.onSurfaceVariant)
            .padding(.top, VelocitySpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    LocationSearchView(
        tripStore: TripSessionStore(),
        settingsStore: UserSettingsStore(),
        mapViewModel: MapViewModel(tripStore: TripSessionStore(), services: .preview),
        onDismiss: nil
    )
}

