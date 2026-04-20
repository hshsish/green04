
//
//  DayCellView.swift
//  green04
//
//  Created by Karina Kazbekova on 07.04.2026.
//

import SwiftUI

struct DayCellView: View {
    let day: CalendarDay
    let isSelected: Bool
    let namespace: Namespace.ID?
    
    // ✅ Обновлено: теперь колбэк принимает дату
    let onDaySelected: (Date) -> Void
    let hasMood: Bool
    
    private let calendar = Calendar.current
    
    // ✅ Цвета сердечек
    private var backgroundColor: Color {
        if day.isToday { return .appPrimary }
        if day.isInCurrentMonth { return .appAccent.opacity(0.35) }
        return .appPrimary.opacity(0.1)
    }
    
    // ✅ Цвета текста
    private var textColor: Color {
        if day.isToday { return .white }
        if day.isInCurrentMonth { return .appPrimary }
        return .appPrimary.opacity(0.35)
    }
    
    private var dayNumber: Int {
        calendar.component(.day, from: day.date)
    }
    
    var body: some View {
        Button {
            // ✅ Передаём дату дня в родительский вид
            onDaySelected(day.date)
        } label: {
            content
        }
        .buttonStyle(.plain)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var content: some View {
        ZStack {
            Image(systemName: "heart.fill")
                .foregroundColor(backgroundColor)
                .font(.system(size: 32, weight: .bold))
                .scaleEffect(day.isToday ? 1.1 : 1.0)
                .shadow(
                    color: day.isToday ? .appPrimary.opacity(0.4) : .clear,
                    radius: day.isToday ? 8 : 0,
                    y: 2
                )
                .if(isSelected && namespace != nil) { view in
                    view.matchedGeometryEffect(
                        id: "heart_\(day.date.timeIntervalSince1970)",
                        in: namespace!
                    )
                }
            
            Text("\(dayNumber)")
                .font(.custom("SLIZING", size: 17, relativeTo: .title))
                .foregroundColor(textColor)
            
            // ✅ Индикатор настроения
            if hasMood {
                Circle()
                    .fill(Color.appPrimary)
                    .frame(width: 6, height: 6)
                    .offset(x: 14, y: 14)
            }
        }
    }
}

// MARK: - Equatable
extension DayCellView: Equatable {
    static func == (lhs: DayCellView, rhs: DayCellView) -> Bool {
        lhs.day.date == rhs.day.date &&
        lhs.day.isInCurrentMonth == rhs.day.isInCurrentMonth &&
        lhs.day.isToday == rhs.day.isToday &&
        lhs.hasMood == rhs.hasMood
    }
}

// MARK: - View Helper
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
