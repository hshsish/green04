//
//  CalendarViewModel.swift
//  green04
//
//  Created by Karina Kazbekova on 07.04.2026.
//


//
//  CalendarViewModel.swift
//  green03
//
//  Created by Karina Kazbekova on 05.04.2026.
//

import SwiftUI

//@MainActor
//final class CalendarViewModel: ObservableObject, CalendarViewModelProtocol {
//    private let useCase: GetDaysForMonthUseCase
//    private let calendar: Calendar
//    private let locale: Locale
//    
//    @Published var months: [Date] = []
//    
//    private var daysCache: [String: [CalendarDay]] = [:]
//    private var titleCache: [String: String] = [:]
//    
//    private let titleFormatter: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "LLLL yyyy"
//        return formatter
//    }()
//    
//    init(
//        useCase: GetDaysForMonthUseCase,
//        calendar: Calendar = .current,
//        locale: Locale = .current
//    ) {
//        self.useCase = useCase
//        self.calendar = calendar
//        self.locale = locale
//        self.titleFormatter.locale = locale
//        generateMonths()
//    }
//    
//    private func generateMonths() {
//        var result: [Date] = []
//        result.reserveCapacity(36)
//        
//        let currentYear = calendar.component(.year, from: Date())
//        let currentMonth = calendar.component(.month, from: Date())
//        
//        guard let start = calendar.date(
//            from: DateComponents(year: currentYear, month: currentMonth - 18, day: 1)
//        ) else { return }
//        
//        for i in 0..<36 {
//            if let monthDate = calendar.date(byAdding: .month, value: i, to: start) {
//                result.append(monthDate)
//            }
//        }
//        months = result
//    }
//    
//    private func cacheKey(for date: Date) -> String {
//        let components = calendar.dateComponents([.year, .month], from: date)
//        return "\(components.year ?? 0)-\(components.month ?? 0)"
//    }
//    
//    func getDays(for index: Int) -> [CalendarDay]? {
//        guard index < months.count else { return nil }
//        let monthDate = months[index]
//        let key = cacheKey(for: monthDate)
//        
//        if let cached = daysCache[key] {
//            return cached
//        }
//        
//        do {
//            let days = try useCase.execute(for: monthDate)
//            daysCache[key] = days
//            return days
//        } catch {
//            return nil
//        }
//    }
//    
//    func monthTitle(for date: Date) -> String {
//        let key = cacheKey(for: date)
//        
//        if let cached = titleCache[key] {
//            return cached
//        }
//        
//        let title = titleFormatter.string(from: date).capitalized
//        titleCache[key] = title
//        return title
//    }
//}
//
//  CalendarViewModel.swift
//  green03
//
//  Created by Karina Kazbekova on 05.04.2026.
//

import SwiftUI

@MainActor
final class CalendarViewModel: ObservableObject, CalendarViewModelProtocol {
    private let useCase: GetDaysForMonthUseCase
    private let calendar: Calendar
    private let locale: Locale
    
    @Published var months: [Date] = []
    
    private var daysCache: [String: [CalendarDay]] = [:]
    private var titleCache: [String: String] = [:]
    
    private let titleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()
    
    init(
        useCase: GetDaysForMonthUseCase,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.useCase = useCase
        self.calendar = calendar
        self.locale = locale
        self.titleFormatter.locale = locale
        generateMonths()
    }
    
    private func generateMonths() {
        var result: [Date] = []
        result.reserveCapacity(36)
        
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        
        guard let start = calendar.date(
            from: DateComponents(year: currentYear, month: currentMonth - 18, day: 1)
        ) else { return }
        
        for i in 0..<36 {
            if let monthDate = calendar.date(byAdding: .month, value: i, to: start) {
                result.append(monthDate)
            }
        }
        months = result
    }
    
    private func cacheKey(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }
    
    func getDays(for index: Int) -> [CalendarDay]? {
        guard index < months.count else { return nil }
        let monthDate = months[index]
        let key = cacheKey(for: monthDate)
        
        if let cached = daysCache[key] {
            return cached
        }
        
        do {
            let days = try useCase.execute(for: monthDate)
            daysCache[key] = days
            return days
        } catch {
            return nil
        }
    }
    
    func monthTitle(for date: Date) -> String {
        let key = cacheKey(for: date)
        
        if let cached = titleCache[key] {
            return cached
        }
        
        let title = titleFormatter.string(from: date).capitalized
        titleCache[key] = title
        return title
    }
}
