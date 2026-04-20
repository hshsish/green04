
//
//  File.swift
//  green03
//
//  Created by Karina Kazbekova on 04.04.2026.
//
import Foundation

struct CalendarDay: Equatable {
    let date: Date
    let isInCurrentMonth: Bool
    let isToday: Bool
}

extension CalendarDay: Identifiable {
    var id: Date { date }
}
