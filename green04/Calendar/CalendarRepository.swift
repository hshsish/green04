

//
//  CalendarRepository.swift
//  green03
//
//  Created by Karina Kazbekova on 05.04.2026.
//


import Foundation

final class CalendarRepository: CalendarRepositoryProtocol {
    private let calendar: Calendar
    
    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }
    
    func getDays(for monthDate: Date) throws -> [CalendarDay] {
        guard let interval = calendar.dateInterval(of: .month, for: monthDate) else {
            throw CalendarError.invalidDateInterval
        }
        
        guard let daysInMonthRange = calendar.range(of: .day, in: .month, for: monthDate) else {
            throw CalendarError.failedToGenerateDays
        }
        let daysInMonth = daysInMonthRange.count
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [CalendarDay] = []
        days.reserveCapacity(42)
        
        for i in 0..<offset {
            if let date = calendar.date(byAdding: .day, value: -(offset - i), to: interval.start) {
                days.append(CalendarDay(
                    date: date,
                    isInCurrentMonth: false,
                    isToday: calendar.isDateInToday(date)
                ))
            }
        }
        
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: interval.start) {
                days.append(CalendarDay(
                    date: date,
                    isInCurrentMonth: true,
                    isToday: calendar.isDateInToday(date)
                ))
            }
        }
        
        let remaining = 42 - days.count
        for i in 0..<remaining {
            if let date = calendar.date(byAdding: .day, value: daysInMonth + i, to: interval.start) {
                days.append(CalendarDay(
                    date: date,
                    isInCurrentMonth: false,
                    isToday: calendar.isDateInToday(date)
                ))
            }
        }
        
        return days
    }
}
