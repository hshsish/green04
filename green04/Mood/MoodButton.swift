//
//  MoodButton.swift
//  green04
//
//  Created by Karina Kazbekova on 10.04.2026.
//
import SwiftUI

struct MoodButton: View {
    let mood: MoodType
    let isSelected: Bool
    let isAnimating: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                // 🎭 Эмодзи с эффектом свечения
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(mood.glowColor)
                            .frame(width: 70, height: 70)
                            .blur(radius: 15)
                            .opacity(isAnimating ? 1 : 0)
                            .scaleEffect(isAnimating ? 1.3 : 1)
                    }
                    
                    Text(mood.emoji)
                        .font(.system(size: 40))
                        .scaleEffect(isSelected ? 1.15 : 1.0)
                }
                
                // 🏷️ Подпись
                Text(mood.label)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.85))
            }
            .frame(width: 84, height: 100)
            .background {
                // 🎨 Фон кнопки
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                isSelected ? mood.accentColor.opacity(0.25) : Color.white.opacity(0.08),
                                isSelected ? mood.accentColor.opacity(0.1) : Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? mood.accentColor : Color.white.opacity(0.15),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? mood.glowColor : .clear,
                        radius: isSelected ? 20 : 0,
                        y: 8
                    )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // 🎬 Микро-анимации
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
