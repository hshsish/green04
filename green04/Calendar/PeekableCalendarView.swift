//
//  PeekableCalendarView.swift
//  green04
//
//  Created by Karina Kazbekova on 05.04.2026.
//

import SwiftUI

struct PeekableCalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    // ✅ Константы
    private let peekOffset: CGFloat = 100
    private let cardScale: CGFloat = 0.92
    private let verticalSpacing: CGFloat = 0.71
    private let currentPalette: [Color] = [.purple, .pink, .yellow, .red]
    
    @State private var currentIndex: Int
    @State private var selectedDay: Date?      // ✅ Дата для навигации
    @State private var showDayDetail: Bool = false  // ✅ Флаг открытия экрана
    
    init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
        let now = Date()
        let calendar = Calendar.current
        let initialIndex = viewModel.months.firstIndex {
            calendar.isDate($0, equalTo: now, toGranularity: .month)
        } ?? 0
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        
        // ✅ NavigationStack обязателен для работы .navigationDestination
        NavigationStack {
            GeometryReader { geo in
                contentView(for: geo.size)
            }
            .ignoresSafeArea()
            .navigationDestination(isPresented: $showDayDetail) {
                if let date = selectedDay {
                    let repo = UserDefaultsMoodRepository()
                    
                    // ✅ Читаем ключи из Info.plist — НИКАКИХ пустых строк!
                    let apiKey = (Bundle.main.object(forInfoDictionaryKey: "YandexAPIKey") as? String ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let folderId = (Bundle.main.object(forInfoDictionaryKey: "YandexFolderID") as? String ?? "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // ✅ Теперь передаём реальные значения
                    DayDetailView(
                        selectedDate: date,
                        repository: repo,
                        aiClient: YandexGPTClient(apiKey: apiKey, folderId: folderId, source: "PeekableCalendarView.navigationDestination")
                    )
                }
            }
            .onAppear {
                Task { await debugPrintMoodData() }
            }
        }
    }
    
    // MARK: - Extracted Body
    
    @ViewBuilder
    private func contentView(for size: CGSize) -> some View {
        let cardWidth = size.width * cardScale
        let cardHeight = (size.height - peekOffset * 2) * cardScale
        let step = (size.height - peekOffset * 2) * verticalSpacing
        
        ZStack {
            backgroundLayer
            calendarCardsLayer(size: size, cardWidth: cardWidth, cardHeight: cardHeight, step: step)
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .gesture(dragGesture(size: size))
    }
    
    // MARK: - Background Layer
    
    private var backgroundLayer: some View {
        ZStack {
            Color.black
            rotatingGradientLayer
            vignetteLayer
        }
        .ignoresSafeArea()
    }
    
    private var rotatingGradientLayer: some View {
        TimelineView(.animation) { timeline in
            let cycleDuration: TimeInterval = 30.0
            let progress = timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
            let angle = progress * 360.0
            
            AngularGradient(
                gradient: Gradient(colors: currentPalette),
                center: .center,
                startAngle: .degrees(0),
                endAngle: .degrees(360)
            )
            .rotationEffect(.degrees(angle))
            .scaleEffect(3.0)
            .blur(radius: 60)
            .drawingGroup(opaque: false)
        }
    }
    
    private var vignetteLayer: some View {
        RadialGradient(
            colors: [.clear, Color.black.opacity(0.1)],
            center: .center,
            startRadius: 0,
            endRadius: 400
        )
    }
    
    // MARK: - Calendar Cards Layer
    
    @ViewBuilder
    private func calendarCardsLayer(size: CGSize, cardWidth: CGFloat, cardHeight: CGFloat, step: CGFloat) -> some View {
        let range = visibleRange()
        
        ForEach(Array(range), id: \.self) { i in
            cardView(for: i, size: size, cardWidth: cardWidth, cardHeight: cardHeight, step: step)
        }
    }
    
    private func visibleRange() -> ClosedRange<Int> {
        max(0, currentIndex - 3)...min(viewModel.months.count - 1, currentIndex + 3)
    }
    
    @ViewBuilder
    private func cardView(for i: Int, size: CGSize, cardWidth: CGFloat, cardHeight: CGFloat, step: CGFloat) -> some View {
        let yOffset = CGFloat(i - currentIndex) * step
        let isVisible = abs(i - currentIndex) <= 3
        
        if let days = viewModel.getDays(for: i) {
            MonthCardView(
                monthTitle: viewModel.monthTitle(for: viewModel.months[i]),
                days: days,
                weekdaySymbols: weekdaySymbols,
                isCenter: i == currentIndex,
                onDaySelected: { date in  // ✅ Обработчик выбора дня
                    selectedDay = date
                    showDayDetail = true
                }
            )
            .frame(width: cardWidth, height: cardHeight)
            .offset(y: yOffset)
            .zIndex(zIndex(for: i))
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.95)
            .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.85), value: currentIndex)
        }
    }
    
    private func zIndex(for index: Int) -> Double {
        index == currentIndex ? 100 : 50 - Double(abs(index - currentIndex))
    }
    
    // MARK: - Gesture
    
    private func dragGesture(size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { _ in }
            .onEnded { value in
                handleDragEnd(value, size: size)
            }
    }
    
    private func handleDragEnd(_ value: DragGesture.Value, size: CGSize) {
        let threshold = size.height * 0.15
        let velocity = value.predictedEndLocation.y - value.location.y
        var newIndex = currentIndex
        
        if value.translation.height < -threshold || velocity < -500 {
            newIndex = min(currentIndex + 1, viewModel.months.count - 1)
        } else if value.translation.height > threshold || velocity > 500 {
            newIndex = max(currentIndex - 1, 0)
        }
        currentIndex = newIndex
    }
    
    // MARK: - Helper: Weekday Symbols
    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.shortWeekdaySymbols
        let first = calendar.firstWeekday
        guard first > 1 else { return symbols }
        return Array(symbols.dropFirst(first - 1) + symbols.prefix(first - 1))
    }
}

// MARK: - Debug Helper
extension PeekableCalendarView {
    @MainActor
    private func debugPrintMoodData() async {
        let defaults = UserDefaults.standard
        let storageKey = "mood_records_v2"
        
        print("\n🔍 === MOOD DATA DEBUG ===")
        guard let data = defaults.data(forKey: storageKey) else {
            print("⚪ Нет данных в UserDefaults")
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        do {
            let records = try decoder.decode([String: DailyMoodRecord].self, from: data)
            if records.isEmpty {
                print("⚪ Словарь записей пуст")
            } else {
                print("📦 Найдено дней: \(records.count)")
                let sorted = records.sorted { $0.key < $1.key }
                for (dateKey, record) in sorted {
                    print("\n📅 \(dateKey):")
                    print("   🌅 Morning: \(record.morning?.rawValue ?? "—") \(record.morning?.emoji ?? "")")
                    print("   ☀️  Afternoon: \(record.afternoon?.rawValue ?? "—") \(record.afternoon?.emoji ?? "")")
                    print("   🌙 Evening: \(record.evening?.rawValue ?? "—") \(record.evening?.emoji ?? "")")
                    print("   ✅ Заполнено: \(record.filledCount)/3")
                }
            }
        } catch {
            print("❌ Ошибка декодирования: \(error)")
        }
        print("=== END DEBUG ===\n")
    }
}
