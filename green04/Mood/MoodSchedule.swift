
import SwiftUI
import Foundation

import Foundation
import SwiftUI

public struct HourMinute: Hashable {
    public let hour: Int
    public let minute: Int
    public init(hour: Int, minute: Int) { self.hour = hour; self.minute = minute }
}

public struct TimeSlot: Hashable {
    public let time: HourMinute
    public let type: MoodTimeSlot
    public var identifier: String { "\(type.rawValue)_\(time.hour):\(time.minute)" }
    public init(time: HourMinute, type: MoodTimeSlot) { self.time = time; self.type = type }
}

public struct MoodSchedule {
    public static let morning = TimeSlot(time: HourMinute(hour: 9, minute: 0), type: .morning)
    public static let afternoon = TimeSlot(time: HourMinute(hour: 15, minute: 0), type: .afternoon)
    public static let evening = TimeSlot(time: HourMinute(hour: 21, minute: 0), type: .evening)
    public static let all: [TimeSlot] = [morning, afternoon, evening]
    public static func slot(for type: MoodTimeSlot) -> TimeSlot? { all.first { $0.type == type } }
}

@MainActor
public class TimeSlotScheduler: ObservableObject {
    @Published public var activeSlot: TimeSlot?
    @Published public var pendingMissedSlots: [TimeSlot] = []
    @Published public var shouldShowMoodRing: Bool = false
    @Published public var isCatchUpMode: Bool = false
    @Published public var isReady: Bool = false
    private let calendar: Calendar
    private let repository: MoodCompletionRepository
    private var timer: Timer?
    private let catchUpEnabled: Bool
    private let slotWindow: TimeInterval = 30 * 60
    
    // ✅ 1. Основной init (синхронно вычисляет состояние ДО рендера)
    public init(calendar: Calendar = .current, catchUpEnabled: Bool = true) {
        self.calendar = calendar
        self.repository = UserDefaultsCompletionRepository()
        self.catchUpEnabled = catchUpEnabled
        
        performSyncCheck() // 🔥 Мгновенная проверка
        startMonitoring()
    }
    
    // ✅ 2. Init для тестов/DI
    public init(calendar: Calendar, repository: MoodCompletionRepository, catchUpEnabled: Bool = true) {
        self.calendar = calendar
        self.repository = repository
        self.catchUpEnabled = catchUpEnabled
        
        performSyncCheck()
        startMonitoring()
    }
    
    deinit { timer?.invalidate() }
    
    // 🚀 Синхронная проверка (работает <1мс, не блокирует UI)
    private func performSyncCheck() {
        let now = Date()
        let today = calendar.startOfDay(for: now)
        var missedQueue: [TimeSlot] = []
        
        if catchUpEnabled {
            for slot in MoodSchedule.all {
                guard var slotDate = calendar.date(byAdding: .day, value: 0, to: today) else { continue }
                slotDate = calendar.date(bySetting: .hour, value: slot.time.hour, of: slotDate) ?? slotDate
                slotDate = calendar.date(bySetting: .minute, value: slot.time.minute, of: slotDate) ?? slotDate
                
                if now.timeIntervalSince(slotDate) > slotWindow {
                    if !repository.isCompletedSync(slot.type, for: today) {
                        missedQueue.append(slot)
                    }
                }
            }
            isReady = true
        }
        
        if let current = findCurrentlyActiveSlot(for: today, now: now) {
            if !repository.isCompletedSync(current.type, for: today) &&
               !missedQueue.contains(where: { $0.type == current.type }) {
                missedQueue.append(current)
            }
        }
        
        // Сразу применяем состояние (до вызова body)
        if !missedQueue.isEmpty {
            pendingMissedSlots = missedQueue
            activeSlot = missedQueue.first
            shouldShowMoodRing = true
            isCatchUpMode = !missedQueue.isEmpty
        }
    }
    
    private func startMonitoring() {
        // Асинхронное уточнение через 0.2 сек
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 200_000_000)
            await self?.checkSlots()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.checkSlots() }
        }
    }
    
    public func checkSlots() async {
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        var missedQueue: [TimeSlot] = []
        if catchUpEnabled {
            for slot in MoodSchedule.all {
                guard var slotDate = calendar.date(byAdding: .day, value: 0, to: today) else { continue }
                slotDate = calendar.date(bySetting: .hour, value: slot.time.hour, of: slotDate) ?? slotDate
                slotDate = calendar.date(bySetting: .minute, value: slot.time.minute, of: slotDate) ?? slotDate
                
                if now.timeIntervalSince(slotDate) > slotWindow {
                    if !(await repository.isCompleted(slot.type, for: today)) {
                        missedQueue.append(slot)
                    }
                }
            }
        }
        
        var currentActive: TimeSlot? = nil
        if let slot = findCurrentlyActiveSlot(for: today, now: now) {
            if !(await repository.isCompleted(slot.type, for: today)) {
                currentActive = slot
            }
        }
        
        let allPending = missedQueue + (currentActive.map { [$0] } ?? [])
        
        if allPending.map { $0.identifier } != pendingMissedSlots.map { $0.identifier } {
            withAnimation(.easeInOut(duration: 0.2)) {
                if !allPending.isEmpty {
                    pendingMissedSlots = allPending
                    activeSlot = allPending.first
                    shouldShowMoodRing = true
                    isCatchUpMode = !missedQueue.isEmpty
                } else {
                    pendingMissedSlots = []
                    activeSlot = nil
                    shouldShowMoodRing = false
                    isCatchUpMode = false
                }
            }
        }
    }
    
    public func markCompleted(_ slot: MoodTimeSlot) async {
        let today = calendar.startOfDay(for: Date())
        await repository.markCompleted(slot, for: today)
        
        pendingMissedSlots.removeAll { $0.type == slot }
        
        if !pendingMissedSlots.isEmpty {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                activeSlot = pendingMissedSlots.first
                isCatchUpMode = true
            }
        } else {
            await checkSlots()
        }
    }
    
    public func dismissMoodRing() {
        withAnimation(.easeOut(duration: 0.3)) {
            shouldShowMoodRing = false
            activeSlot = nil
            pendingMissedSlots = []
        }
    }
    
    #if DEBUG
    public func debug_activateSlot(_ slot: MoodTimeSlot) {
        pendingMissedSlots = [MoodSchedule.slot(for: slot)!]
        activeSlot = pendingMissedSlots.first
        shouldShowMoodRing = true
        isCatchUpMode = false
    }
    public func debug_resetDay() async {
        await repository.resetDay(calendar.startOfDay(for: Date()))
        await checkSlots()
    }
    #endif
    
    private func findCurrentlyActiveSlot(for today: Date, now: Date) -> TimeSlot? {
        for slot in MoodSchedule.all {
            guard var slotDate = calendar.date(byAdding: .day, value: 0, to: today) else { continue }
            slotDate = calendar.date(bySetting: .hour, value: slot.time.hour, of: slotDate) ?? slotDate
            slotDate = calendar.date(bySetting: .minute, value: slot.time.minute, of: slotDate) ?? slotDate
            if abs(now.timeIntervalSince(slotDate)) <= slotWindow { return slot }
        }
        return nil
    }
}
