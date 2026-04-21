
import Foundation

protocol CalendarViewModelProtocol {
    var months: [Date] { get }
    func getDays(for index: Int) -> [CalendarDay]?
    func monthTitle(for date: Date) -> String
}
