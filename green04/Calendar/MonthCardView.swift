import SwiftUI

struct MonthCardView: View {
    let monthTitle: String
    let days: [CalendarDay]
    let weekdaySymbols: [String]
    let isCenter: Bool
    let onDaySelected: (Date) -> Void
    
    private let rowsCount = 6
    private let colsCount = 7
    private let cellSize: CGFloat = 44
    
    var body: some View {
        VStack(spacing: 6) {
            monthTitleView
            weekdaysView
            daysGridView
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.85))
        }
        .drawingGroup(opaque: false)
        .navigationBarBackButtonHidden()
    }
    
    private var monthTitleView: some View {
        Text(monthTitle)
            .font(.custom("SLIZING", size: 40, relativeTo: .title))
            .foregroundColor(Color.appPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var weekdaysView: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { wd in
                Text(wd)
                    .font(.custom("SLIZING", size: 24, relativeTo: .title))
                    .foregroundColor(.appPrimary.opacity(0.5))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 4)
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder
    private var daysGridView: some View {
        VStack(spacing: 6) {
            ForEach(0..<rowsCount, id: \.self) { row in
                dayRow(for: row)
            }
        }
    }
    
    @ViewBuilder
    private func dayRow(for row: Int) -> some View {
        let start = row * colsCount
        let end = min(start + colsCount, days.count)
        
        HStack(spacing: 2) {
            if start < days.count {
                ForEach(days[start..<end], id: \.id) { day in
                    dayCell(for: day)
                }
            }
            emptyCellsView(start: end, end: start + colsCount)
        }
    }
    
    @ViewBuilder
    private func emptyCellsView(start: Int, end: Int) -> some View {
        if start < end {
            ForEach(start..<end, id: \.self) { _ in
                Color.clear
                    .frame(width: cellSize, height: cellSize)
            }
        }
    }
    
    private func hasMood(for date: Date) -> Bool {
        let key = "mood_records_v2"
        guard let data = UserDefaults.standard.data(forKey: key) else { return false }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        do {
            let records = try decoder.decode([String: DailyMoodRecord].self, from: data)
            let dayKey = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: date))
            guard let record = records[dayKey] else { return false }
            return record.morning != nil || record.afternoon != nil || record.evening != nil
        } catch {
            return false
        }
    }

    @ViewBuilder
    private func dayCell(for day: CalendarDay) -> some View {
        DayCellView(
            day: day,
            isSelected: false,
            hasMood: hasMood(for: day.date),
            namespace: nil,
            onDaySelected: onDaySelected
        )
    }
}

extension MonthCardView: Equatable {
    static func == (lhs: MonthCardView, rhs: MonthCardView) -> Bool {
        lhs.monthTitle == rhs.monthTitle &&
        lhs.days == rhs.days &&
        lhs.isCenter == rhs.isCenter
    }
}
