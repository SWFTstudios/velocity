//
//  StitchExportsRootView.swift
//  Velocity
//
//  Developer gallery for imported Stitch screenshots and bundled exports.
//

import SwiftUI

struct StitchExportsRootView: View {
    var body: some View {
        List {
            Section("Design system") {
                NavigationLink("Midnight Calm (spec)") {
                    DesignSystemStitchView()
                }
            }

            Section("Screens (Stitch → asset + HTML)") {
                NavigationLink("Home – Map Search") {
                    HomeMapSearchStitchView()
                }
                NavigationLink("Alarm setup") {
                    RedesignedAlarmSetupStitchView()
                }
                NavigationLink("Sleep map / route") {
                    SleepMapRouteInProgressStitchView()
                }
                NavigationLink("Sleep sounds") {
                    SleepSoundsMeditationStitchView()
                }
                NavigationLink("Wake-up alert") {
                    WakeUpAlertStitchView()
                }
                NavigationLink("App settings") {
                    AppSettingsStitchView()
                }
            }
        }
        .navigationTitle("Stitch exports")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StitchExportsRootView()
    }
}
