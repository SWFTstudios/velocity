//
//  HistoryView.swift
//  Velocity
//

import SwiftUI

struct HistoryView: View {
    @Bindable var viewModel: HistoryViewModel

    var body: some View {
        Group {
            if viewModel.hasRecords {
                List {
                    ForEach(viewModel.records) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(record.destination.title)
                                .font(VelocityFontStyle.title(16))
                                .foregroundStyle(VelocityColor.onSurface)
                            Text("\(record.mode.displayName) • \(record.startedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(VelocityFontStyle.body(13))
                                .foregroundStyle(VelocityColor.onSurfaceVariant)
                            HStack {
                                if let distance = record.finalDistanceMeters {
                                    Text(distanceText(distance))
                                } else {
                                    Text("Distance —")
                                }
                                Spacer()
                                Text(durationText(record.durationSeconds))
                                Spacer()
                                Text(record.wasAwakened ? "Awakened" : "Ended")
                                    .foregroundStyle(record.wasAwakened ? VelocityColor.primary : VelocityColor.onSurfaceVariant)
                            }
                            .font(VelocityFontStyle.body(12))
                            .foregroundStyle(VelocityColor.onSurfaceVariant)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(VelocityColor.surfaceContainer)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(VelocityColor.surface)
            } else {
                ContentUnavailableView(
                    "History",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Trips, naps, and wake events will appear here after your first trip.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(VelocityColor.surface.ignoresSafeArea())
            }
        }
        .navigationTitle("History")
        .toolbar {
            if viewModel.hasRecords {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        viewModel.clearAll()
                    }
                    .foregroundStyle(VelocityColor.primary)
                }
            }
        }
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds / 60)
        let hrs = mins / 60
        let rem = mins % 60
        if hrs > 0 {
            return "\(hrs)h \(rem)m"
        }
        return "\(mins)m"
    }

    private func distanceText(_ meters: Double) -> String {
        switch UserSettingsStore.currentMeasurementUnit() {
        case .kilometers:
            return String(format: "%.1f km", meters / 1000)
        case .miles:
            return String(format: "%.1f mi", meters / 1609.344)
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView(viewModel: HistoryViewModel(historyStore: TripHistoryStore()))
    }
}

