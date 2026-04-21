import SwiftUI

struct DayCellView: View {
    @StateObject private var viewModel: DayCellViewModel
    let day: CalendarDay
    let hasMood: Bool
    let namespace: Namespace.ID?
    let isSelected: Bool
    
    init(day: CalendarDay, isSelected: Bool, hasMood: Bool, namespace: Namespace.ID?, onDaySelected: @escaping (Date) -> Void) {
        self.day = day
        self.hasMood = hasMood
        self.isSelected = isSelected
        self.namespace = namespace
        self._viewModel = StateObject(wrappedValue: DayCellViewModel(calendarDay: day, hasMood: hasMood, onDaySelected: onDaySelected))
    }
    
    var body: some View {
        Button(action: viewModel.handleSelection) {
            ZStack {
                heartView
                dayText
                moodDot
            }
        }
        .buttonStyle(.plain)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var heartView: some View {
        let base = Image(systemName: "heart.fill")
            .foregroundColor(viewModel.backgroundColor)
            .font(.system(size: 32, weight: .bold))
            .scaleEffect(viewModel.heartScale)
            .shadow(color: viewModel.shadowColor, radius: viewModel.shadowRadius, y: 2)
        
        if isSelected, let namespace = namespace {
            base.matchedGeometryEffect(id: viewModel.matchedGeometryId, in: namespace)
        } else {
            base
        }
    }
    
    @ViewBuilder
    private var dayText: some View {
        Text("\(viewModel.dayNumber)")
            .font(.custom("SLIZING", size: 17, relativeTo: .title))
            .foregroundColor(viewModel.textColor)
    }
    
    @ViewBuilder
    private var moodDot: some View {
        if viewModel.shouldShowMoodIndicator {
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 6, height: 6)
                .offset(x: 14, y: 14)
        }
    }
}

extension DayCellView: Equatable {
    static func == (lhs: DayCellView, rhs: DayCellView) -> Bool {
        lhs.day.date == rhs.day.date &&
        lhs.day.isInCurrentMonth == rhs.day.isInCurrentMonth &&
        lhs.day.isToday == rhs.day.isToday &&
        lhs.hasMood == rhs.hasMood
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
