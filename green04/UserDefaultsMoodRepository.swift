
import Foundation

public final class UserDefaultsMoodRepository: MoodRepository {
    private let defaults: UserDefaults
    private let calendar: Calendar
    private let storageKey = "mood_records_v2"
    
    public init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }
    private func dateKey(for date: Date) -> String {
        let start = calendar.startOfDay(for: date)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: start)
    }
    
    private func loadRecords() -> [String: DailyMoodRecord] {
        guard let data = defaults.data(forKey: storageKey) else { return [:] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return (try? decoder.decode([String: DailyMoodRecord].self, from: data)) ?? [:]
    }
    
    private func saveRecords(_ records: [String: DailyMoodRecord]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        if let data = try? encoder.encode(records) {
            defaults.set(data, forKey: storageKey)
        }
    }
    
    public func saveMood(_ mood: MoodType, for slot: MoodTimeSlot, date: Date) async throws {
        var records = loadRecords()
        let key = dateKey(for: date)
        var record = records[key] ?? DailyMoodRecord(date: calendar.startOfDay(for: date))
        record[slot] = mood
        records[key] = record
        saveRecords(records)
    }
    
    public func getMood(for slot: MoodTimeSlot, date: Date) async throws -> MoodType? {
        loadRecords()[dateKey(for: date)]?[slot]
    }
    
    public func getRecord(for date: Date) async throws -> DailyMoodRecord? {
        loadRecords()[dateKey(for: date)]
    }
    
    public func isCompletedSync(_ slot: MoodTimeSlot, for date: Date) -> Bool {
        guard let data = defaults.data(forKey: storageKey) else { return false }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        guard let records = try? decoder.decode([String: DailyMoodRecord].self, from: data) else { return false }
        return records[dateKey(for: date)]?[slot] != nil
    }
}
