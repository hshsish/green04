import SwiftUI

@MainActor
final class DayCellViewModel: ObservableObject {
    private let calendarDay: CalendarDay
    private let hasMood: Bool
    private let calendar: Calendar
    
    let onDaySelected: (Date) -> Void
    
    init(calendarDay: CalendarDay, hasMood: Bool, onDaySelected: @escaping (Date) -> Void) {
        self.calendarDay = calendarDay
        self.hasMood = hasMood
        self.onDaySelected = onDaySelected
        self.calendar = .current
    }
    
    var dayNumber: Int {
        calendar.component(.day, from: calendarDay.date)
    }
    
    var backgroundColor: Color {
        if calendarDay.isToday { return .appPrimary }
        if calendarDay.isInCurrentMonth { return .appAccent.opacity(0.35) }
        return .appPrimary.opacity(0.1)
    }
    
    var textColor: Color {
        if calendarDay.isToday { return .white }
        if calendarDay.isInCurrentMonth { return .appPrimary }
        return .appPrimary.opacity(0.35)
    }
    
    var heartScale: CGFloat {
        calendarDay.isToday ? 1.1 : 1.0
    }
    
    var shadowColor: Color {
        calendarDay.isToday ? .appPrimary.opacity(0.4) : .clear
    }
    
    var shadowRadius: CGFloat {
        calendarDay.isToday ? 8 : 0
    }
    
    var matchedGeometryId: String {
        "heart_\(calendarDay.date.timeIntervalSince1970)"
    }
    
    var shouldShowMoodIndicator: Bool {
        hasMood
    }
    
    func handleSelection() {
        onDaySelected(calendarDay.date)
    }
}

