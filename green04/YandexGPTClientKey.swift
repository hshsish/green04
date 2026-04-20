//
//  YandexGPTClientKey.swift
//  green04
//
//  Created by Karina Kazbekova on 20.04.2026.
//


// YandexGPTClient+Environment.swift
import SwiftUI

// ✅ Ключ для передачи YandexGPTClient через Environment
private struct YandexGPTClientKey: EnvironmentKey {
    static let defaultValue: YandexGPTClient? = nil
}

extension EnvironmentValues {
    var yandexGPTClient: YandexGPTClient? {
        get { self[YandexGPTClientKey.self] }
        set { self[YandexGPTClientKey.self] = newValue }
    }
}