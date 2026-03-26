//
//  HistoryPlaceholderView.swift
//  Velocity
//

import SwiftUI

struct HistoryPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "History",
            systemImage: "clock.arrow.circlepath",
            description: Text("Trips, naps, and wake events will appear here once logging is implemented.")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VelocityColor.surface.ignoresSafeArea())
    }
}

#Preview {
    HistoryPlaceholderView()
}
