//
//  Color.swift
//  green03
//
//  Created by Karina Kazbekova on 05.04.2026.
//

import SwiftUI

extension Color {
    static let appPrimary    = Color(hex: "9c6d82")
    static let appBackground = Color(hex: "f5d0e0")
    static let appAccent     = Color(hex: "f7a6c9")
    
    static let appBackgroundGradient = LinearGradient(
        colors: [Color(hex: "f79cc2"), .white],
        startPoint: .top,
        endPoint: .bottom
    )
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 1, 1, 1)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}
