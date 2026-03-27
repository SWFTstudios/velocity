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
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: VelocitySpacing.md) {
                    searchField

                    if mapViewModel.showsSearchSuggestions, !mapViewModel.searchCompletions.isEmpty {
                        suggestionsList
                    } else if mapViewModel.searchText.isEmpty {
                        quickDestinationsSection
                        emptyState
                    } else {
                        noResultsState
                    }
                }
                .padding(.horizontal, VelocitySpacing.md)
                .padding(.top, VelocitySpacing.md)
                .padding(.bottom, VelocitySpacing.lg)
            }
        }
        .background(VelocityColor.surface.ignoresSafeArea())
        .onAppear {
            if !mapViewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                mapViewModel.syncSearchQuery(mapViewModel.searchText)
            }
            queryFocused = true
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Search Destinations")
                .font(VelocityFontStyle.title(18))
                .foregroundStyle(VelocityColor.onSurface)

            Spacer()

            Button {
                onDismiss?()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(VelocityColor.onSurfaceVariant)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, VelocitySpacing.md)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var searchField: some View {
        HStack(spacing: VelocitySpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(VelocityColor.onSurfaceVariant)

            TextField("Search destinations…", text: $mapViewModel.searchText)
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
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    private var quickDestinationsSection: some View {
        VStack(alignment: .leading, spacing: VelocitySpacing.sm) {
            HStack {
                Text("Quick Destinations")
                    .font(VelocityFontStyle.title(16))
                    .foregroundStyle(VelocityColor.onSurface)
                Spacer()
                Button {
                    onDismiss?()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(VelocityColor.primary)
                }
                .accessibilityLabel("Add quick destination")
                .buttonStyle(.plain)
            }

            HStack(alignment: .center, spacing: VelocitySpacing.md) {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundStyle(VelocityColor.primary)
                    .frame(width: 40, height: 40)
                    .background(VelocityColor.surfaceContainerHighest.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Home")
                        .font(VelocityFontStyle.body())
                        .foregroundStyle(VelocityColor.onSurface)
                    Text("Saved place")
                        .font(VelocityFontStyle.body(12))
                        .foregroundStyle(VelocityColor.onSurfaceVariant)
                }

                Spacer(minLength: 8)

                Text("Home")
                    .font(VelocityFontStyle.label(10))
                    .foregroundStyle(VelocityColor.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(VelocityColor.primary.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(VelocitySpacing.md)
            .background(VelocityColor.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: VelocityRadius.card, style: .continuous))
        }
    }

    private var suggestionsList: some View {
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
        .padding(.top, VelocitySpacing.sm)
    }

    private var emptyState: some View {
        Text("Type a destination to search, or pick from quick destinations later.")
            .font(VelocityFontStyle.body(14))
            .foregroundStyle(VelocityColor.onSurfaceVariant)
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
