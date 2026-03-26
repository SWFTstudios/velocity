//
//  StitchExportResources.swift
//  Velocity
//
//  Loads bundled Stitch export artifacts (design spec markdown).
//

import Foundation

enum StitchExportResources {
    /// Tries common bundle subdirectory layouts for synchronized `Velocity/` roots.
    static func designSystemMarkdown() -> String {
        let name = "DesignSystem"
        let ext = "md"
        let candidates: [String?] = [
            "Features/StitchExports/Raw",
            "StitchExports/Raw",
            "Raw",
            nil,
        ]
        for sub in candidates {
            let url: URL?
            if let sub {
                url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: sub)
            } else {
                url = Bundle.main.url(forResource: name, withExtension: ext)
            }
            if let url, let text = try? String(contentsOf: url, encoding: .utf8) {
                return text
            }
        }
        return """
        Could not load DesignSystem.md from the app bundle.
        Open `Features/StitchExports/Raw/DesignSystem.md` in the project navigator.
        """
    }
}
