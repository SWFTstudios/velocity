//
//  StitchExportScreenViews.swift
//  Velocity
//
//  SwiftUI stand-ins for Stitch HTML exports. Stitch provides HTML, not SwiftUI;
//  these views show the screenshot asset plus a pointer to the raw HTML in the repo/bundle.
//

import SwiftUI

// MARK: - Design system (markdown + tokens; no Stitch screen image for this asset)

struct DesignSystemStitchView: View {
    private let markdown = StitchExportResources.designSystemMarkdown()

    var body: some View {
        ScrollView {
            Text(markdown)
                .font(.system(.footnote, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding()
        }
        .navigationTitle("Design system")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityLabel("Stitch design system specification")
    }
}

// MARK: - Screen exports (image + HTML reference)

private struct StitchScreenExportView: View {
    let title: String
    let imageName: String
    let htmlFileName: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("\(title) Stitch screenshot")

                Text("Stitch exported HTML: `Features/StitchExports/Raw/\(htmlFileName)`")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HomeMapSearchStitchView: View {
    var body: some View {
        StitchScreenExportView(
            title: "Home – Map Search",
            imageName: "HomeMapSearch",
            htmlFileName: "HomeMapSearch.html"
        )
    }
}

struct RedesignedAlarmSetupStitchView: View {
    var body: some View {
        StitchScreenExportView(
            title: "Alarm setup",
            imageName: "RedesignedAlarmSetup",
            htmlFileName: "RedesignedAlarmSetup.html"
        )
    }
}

struct SleepMapRouteInProgressStitchView: View {
    var body: some View {
        StitchScreenExportView(
            title: "Sleep map / route",
            imageName: "SleepMapRouteInProgress",
            htmlFileName: "SleepMapRouteInProgress.html"
        )
    }
}

struct SleepSoundsMeditationStitchView: View {
    var body: some View {
        StitchScreenExportView(
            title: "Sleep sounds",
            imageName: "SleepSoundsMeditation",
            htmlFileName: "SleepSoundsMeditation.html"
        )
    }
}

struct WakeUpAlertStitchView: View {
    var body: some View {
        StitchScreenExportView(
            title: "Wake-up alert",
            imageName: "WakeUpAlert",
            htmlFileName: "WakeUpAlert.html"
        )
    }
}

struct AppSettingsStitchView: View {
    var body: some View {
        StitchScreenExportView(
            title: "App settings",
            imageName: "AppSettings",
            htmlFileName: "AppSettings.html"
        )
    }
}
