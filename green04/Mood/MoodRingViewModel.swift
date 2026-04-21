import SwiftUI
import Combine

@MainActor
class MoodRingViewModel: ObservableObject {
    @Published var selectedMood: MoodType?
    @Published var isAnimating: Bool = false
    @Published var showConfirmation: Bool = false
    
    private let selectMoodUseCase: SelectMoodUseCase
    private let moodRepository: MoodRepository
    private var cancellables = Set<AnyCancellable>()
    
    weak var scheduler: TimeSlotScheduler?
    
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
            
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    isAnimating = false
                    showConfirmation = false
                }
            }
        } catch {
            print("Failed to save mood: \(error)")
        }
    }
    
    func resetSelection() {
        withAnimation(.easeOut(duration: 0.2)) {
            selectedMood = nil
        }
    }
}
