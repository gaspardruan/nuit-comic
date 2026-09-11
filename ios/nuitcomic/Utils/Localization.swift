//
//  Localization.swift
//  nuitcomic
//
//  Created by OpenAI Codex on 2026/4/24.
//

import Foundation

func localizedFormat(_ key: String, _ arguments: CVarArg...) -> String {
    String(
        format: NSLocalizedString(key, comment: ""),
        locale: Locale.current,
        arguments: arguments
    )
}

var prefersChineseLocalization: Bool {
    Locale.preferredLanguages.first?.hasPrefix("zh") == true
}
