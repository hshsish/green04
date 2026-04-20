//
//  MoodModels.swift
//  green04
//
//  Created by Karina Kazbekova on 11.04.2026.
//

import Foundation
import SwiftUI

// MARK: - 🎨 Color Extension


// MARK: - 😊 MoodType
public enum MoodType: String, CaseIterable, Identifiable, Codable {
    case excellent = "excellent"
    case good = "good"
    case neutral = "neutral"
    case bad = "bad"
    case terrible = "terrible"
    
    public var id: String { rawValue }
    
    public var emoji: String {
        switch self {
        case .excellent: return "🤩"
        case .good: return "😊"
        case .neutral: return "😐"
        case .bad: return "😔"
        case .terrible: return "😫"
        }
    }
    
    public var label: String { rawValue.capitalized }
    
    public var accentColor: Color {
        switch self {
        case .excellent: return Color(hex: "#FFD93D")
        case .good: return Color(hex: "#6BCF7F")
        case .neutral: return Color(hex: "#A0AEC0")
        case .bad: return Color(hex: "#F6A4A4")
        case .terrible: return Color(hex: "#E53E3E")
        }
    }
    
    public var glowColor: Color { accentColor.opacity(0.6) }
}

// MARK: - 🕐 MoodTimeSlot
public enum MoodTimeSlot: String, CaseIterable, Identifiable, Codable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    
    public var id: String { rawValue }
    
    public var greeting: String {
        switch self {
        case .morning: return "How's your morning? 🌅"
        case .afternoon: return "How's your day going? ☀️"
        case .evening: return "How was your day? 🌙"
        }
    }
    
    public var displayName: String { rawValue.capitalized }
    
    public var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.fill"
        }
    }
}

// MARK: - 📦 DailyMoodRecord
public struct DailyMoodRecord: Codable, Identifiable, Hashable {
    public let date: Date  // start of day (00:00)
    public var morning: MoodType?
    public var afternoon: MoodType?
    public var evening: MoodType?
    
    public var id: Date { date }
    
    public init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
    }
    
    // ✅ Удобный доступ по слоту: record[.morning] = .good
    public subscript(slot: MoodTimeSlot) -> MoodType? {
        get {
            switch slot {
            case .morning: return morning
            case .afternoon: return afternoon
            case .evening: return evening
            }
        }
        set {
            switch slot {
            case .morning: morning = newValue
            case .afternoon: afternoon = newValue
            case .evening: evening = newValue
            }
        }
    }
    
    public var isComplete: Bool {
        morning != nil && afternoon != nil && evening != nil
    }
    
    public var filledCount: Int {
        [morning, afternoon, evening].compactMap { $0 }.count
    }
}

// MARK: - 🗄️ Repository Protocol (Domain Layer)
public protocol MoodRepository {
    // Асинхронные методы для сохранения/чтения
    func saveMood(_ mood: MoodType, for slot: MoodTimeSlot, date: Date) async throws
    func getMood(for slot: MoodTimeSlot, date: Date) async throws -> MoodType?
    func getRecord(for date: Date) async throws -> DailyMoodRecord?
    
    // ✅ Синхронный метод для мгновенной проверки при запуске (без чёрного экрана)
    func isCompletedSync(_ slot: MoodTimeSlot, for date: Date) -> Bool
}

// MARK: - ⚡ Use Case (Domain Layer)
public struct SelectMoodUseCase {
    private let repository: MoodRepository
    
    public init(repository: MoodRepository) {
        self.repository = repository
    }
    
    public func execute(_ mood: MoodType, for slot: MoodTimeSlot, date: Date = Date()) async throws {
        try await repository.saveMood(mood, for: slot, date: date)
    }
}
