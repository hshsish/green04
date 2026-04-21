
import SwiftUI

@MainActor
class DayDetailViewModel: ObservableObject {
    @Published var record: DailyMoodRecord?
    @Published var isLoading: Bool = true
    @Published var aiAdvice: String?
    @Published var isAdviceLoading: Bool = false
    
    private let repository: MoodRepository
    private let selectedDate: Date
    private let aiClient: YandexGPTClient
    
    init(selectedDate: Date, repository: MoodRepository, aiClient: YandexGPTClient) {
        self.selectedDate = selectedDate
        self.repository = repository
        self.aiClient = aiClient
        Task { await loadData() }
    }
    
    private func loadData() async {
        isLoading = true
        do {
            record = try await repository.getRecord(for: selectedDate)
            if (record?.filledCount ?? 0) > 0 {
                await generateAdvice()
            }
        } catch {
            print("Failed to load record: \(error)")
        }
        isLoading = false
    }
    
    private func generateAdvice() async {
        guard let record = record else { return }
        isAdviceLoading = true
        
        do {
            aiAdvice = try await aiClient.generateWellnessAdvice(
                morning: record.morning?.emoji,
                afternoon: record.afternoon?.emoji,
                evening: record.evening?.emoji,
                date: selectedDate
            )
        } catch let urlError as URLError {
            aiAdvice = "Проверьте соединение с интернетом"
            print("Network Error: \(urlError.localizedDescription) (Code: \(urlError.code.rawValue))")
            
        } catch let decodingError as DecodingError {
            aiAdvice = "Не удалось обработать ответ ИИ"
            print("Decoding Error: \(decodingError)")
            
        } catch {

            aiAdvice = "✨ Берегите себя сегодня. Маленькие шаги ведут к большим переменам."
            print("AI Error: \(error)")
            print("Error type: \(type(of: error))")
        }
        isAdviceLoading = false
    }
    
    func mood(for slot: MoodTimeSlot) -> MoodType? { record?[slot] }
    var filledCount: Int { record?.filledCount ?? 0 }
}

