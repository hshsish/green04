
import Foundation

protocol CalendarRepositoryProtocol {
    func getDays(for monthDate: Date) throws -> [CalendarDay]
}
