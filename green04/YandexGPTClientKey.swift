
import SwiftUI

private struct YandexGPTClientKey: EnvironmentKey {
    static let defaultValue: YandexGPTClient? = nil
}

extension EnvironmentValues {
    var yandexGPTClient: YandexGPTClient? {
        get { self[YandexGPTClientKey.self] }
        set { self[YandexGPTClientKey.self] = newValue }
    }
}
