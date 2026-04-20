import SwiftUI
import Combine

@MainActor
class MoodRingViewModel: ObservableObject {
    // MARK: - Published State
    @Published var selectedMood: MoodType?
    @Published var isAnimating: Bool = false
    @Published var showConfirmation: Bool = false
    
    // MARK: - Dependencies
    private let selectMoodUseCase: SelectMoodUseCase
    private let moodRepository: MoodRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Scheduler reference (weak to avoid retain cycle)
    weak var scheduler: TimeSlotScheduler?
    
    // MARK: - Haptics
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let successNotification = UINotificationFeedbackGenerator()
    
    init(selectMoodUseCase: SelectMoodUseCase, moodRepository: MoodRepository) {
        self.selectMoodUseCase = selectMoodUseCase
        self.moodRepository = moodRepository
        setupHaptics()
    }
    
    private func setupHaptics() {
        impactLight.prepare()
        successNotification.prepare()
    }
    
    // MARK: - Actions
    func selectMood(_ mood: MoodType) {
        impactLight.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedMood = mood
            isAnimating = true
        }
    }
    
    public func saveMood(_ mood: MoodType, for slot: MoodTimeSlot) async {
        do {
            try await selectMoodUseCase.execute(mood, for: slot, date: Date())
            successNotification.notificationOccurred(.success)
            showConfirmation = true
            
            // ✅ Было: 1.5 сек → Стало: 0.3 сек
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    isAnimating = false
                    showConfirmation = false
                }
            }
        } catch {
            print("❌ Failed to save mood: \(error)")
        }
    }
    
    func resetSelection() {
        withAnimation(.easeOut(duration: 0.2)) {
            selectedMood = nil
        }
    }
}
