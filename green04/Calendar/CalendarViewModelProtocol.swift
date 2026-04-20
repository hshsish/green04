//
//  CalendarViewModelProtocol.swift
//  green04
//
//  Created by Karina Kazbekova on 07.04.2026.
//

import Foundation

protocol CalendarViewModelProtocol {
    var months: [Date] { get }
    func getDays(for index: Int) -> [CalendarDay]?
    func monthTitle(for date: Date) -> String
}
