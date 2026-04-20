import SwiftUI
import UIKit

struct MoodRingView: View {
    @ObservedObject var viewModel: MoodRingViewModel
    let activeSlot: TimeSlot
    let isCatchUpMode: Bool
    let scheduler: TimeSlotScheduler
    let onAllCompleted: () -> Void  // ✅ Новый колбэк: "все слоты заполнены, закрой меня"
    
    private let backgroundPalette: [Color] = [.purple, .pink, .yellow, .red]
    
    init(viewModel: MoodRingViewModel,
         activeSlot: TimeSlot,
         isCatchUpMode: Bool,
         scheduler: TimeSlotScheduler,
         onAllCompleted: @escaping () -> Void) {  // ✅ Добавляем параметр
        _viewModel = ObservedObject(wrappedValue: viewModel)
        self.activeSlot = activeSlot
        self.isCatchUpMode = isCatchUpMode
        self.scheduler = scheduler
        self.onAllCompleted = onAllCompleted
    }
    
    var body: some View {
        ZStack {
            backgroundLayer
            contentLayer
                .id(activeSlot)
        }
        .ignoresSafeArea()
        .onAppear {
            if viewModel.selectedMood != nil {
                Task { await handleCompletion() }
            }
        }
    }
    
    // MARK: - Background
    private var backgroundLayer: some View {
        ZStack {
            Color.black
            TimelineView(.animation) { timeline in
                let cycleDuration: TimeInterval = 30.0
                let progress = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: cycleDuration) / cycleDuration
                let angle = progress * 360.0
                AngularGradient(
                    gradient: Gradient(colors: backgroundPalette),
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                )
                .rotationEffect(.degrees(angle))
                .scaleEffect(3.0)
                .blur(radius: 60)
                .drawingGroup(opaque: false)
            }
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.25)],
                center: .center,
                startRadius: 0,
                endRadius: 500
            )
        }
    }
    
    // MARK: - Content
    private var contentLayer: some View {
        VStack(spacing: 24) {
            Spacer()
            headerSection
            moodSelectorSection
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text(activeSlot.type.greeting)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Text(viewModel.selectedMood?.emoji ?? "✨")
                .font(.system(size: 96))
                .scaleEffect(viewModel.selectedMood != nil ? 1.1 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: viewModel.selectedMood)
        }
    }
    
    private var moodSelectorSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ForEach(Array(MoodType.allCases.prefix(3)), id: \.self) { mood in
                    MoodButton(mood: mood, isSelected: viewModel.selectedMood == mood, isAnimating: viewModel.isAnimating) {
                        handleMoodSelection(mood)
                    }
                }
            }
            HStack(spacing: 12) {
                ForEach(Array(MoodType.allCases.suffix(2)), id: \.self) { mood in
                    MoodButton(mood: mood, isSelected: viewModel.selectedMood == mood, isAnimating: viewModel.isAnimating) {
                        handleMoodSelection(mood)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Actions
    private func handleMoodSelection(_ mood: MoodType) {
        viewModel.selectMood(mood)
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            await handleCompletion()
        }
    }
    
    private func handleCompletion() async {
        // 1. Сохраняем настроение
        if let mood = viewModel.selectedMood {
            await viewModel.saveMood(mood, for: activeSlot.type)
        }
        
        // 2. Сбрасываем выбор
        viewModel.resetSelection()
        
        // 3. Запоминаем, был ли это последний слот ДО обновления очереди
        let wasLastSlot = scheduler.pendingMissedSlots.count == 1
        
        // 4. Отмечаем слот как завершённый (это обновит очередь)
        await scheduler.markCompleted(activeSlot.type)
        
        // 5. Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // 6. ✅ Если это был последний слот — явно закрываем оверлей
        if wasLastSlot {
            // Небольшая задержка для анимации подтверждения
            try? await Task.sleep(nanoseconds: 600_000_000)
            await MainActor.run {
                onAllCompleted()
            }
        }
    }
}
