//
//  GetDaysForMonthUseCase.swift
//  green04
//
//  Created by Karina Kazbekova on 07.04.2026.
//

import Foundation

final class GetDaysForMonthUseCase {
    private let repository: CalendarRepositoryProtocol
    
    init(repository: CalendarRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(for date: Date) throws -> [CalendarDay] {
        try repository.getDays(for: date)
    }
}
