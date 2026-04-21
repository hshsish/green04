
import Foundation

public protocol MoodCompletionRepository {
    func isCompleted(_ slot: MoodTimeSlot, for date: Date) async -> Bool
    func markCompleted(_ slot: MoodTimeSlot, for date: Date) async
    func resetDay(_ date: Date) async
    
    func isCompletedSync(_ slot: MoodTimeSlot, for date: Date) -> Bool
}

public class UserDefaultsCompletionRepository: MoodCompletionRepository {
    private let defaults: UserDefaults
    private let keyPrefix = "mood_completed_"
    
    public func isCompletedSync(_ slot: MoodTimeSlot, for date: Date) -> Bool {
           defaults.bool(forKey: storageKey(slot, for: date))
       }
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    public func isCompleted(_ slot: MoodTimeSlot, for date: Date) async -> Bool {
        defaults.bool(forKey: storageKey(slot, for: date))
    }
    
    public func markCompleted(_ slot: MoodTimeSlot, for date: Date) async {
        defaults.set(true, forKey: storageKey(slot, for: date))
    }
    
    public func resetDay(_ date: Date) async {
        for slot in MoodTimeSlot.allCases {
            defaults.removeObject(forKey: storageKey(slot, for: date))
        }
    }
    
    private func storageKey(_ slot: MoodTimeSlot, for date: Date) -> String {
        let day = Calendar.current.startOfDay(for: date)
        let timestamp = Int(day.timeIntervalSince1970)
        return "\(keyPrefix)\(timestamp)_\(slot.rawValue)"
    }
}
