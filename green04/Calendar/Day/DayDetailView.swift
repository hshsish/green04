
import SwiftUI

struct DayDetailView: View {
    let selectedDate: Date
    @StateObject private var viewModel: DayDetailViewModel
    
    @Environment(\.dismiss) private var dismiss
    private let backgroundPalette: [Color] = [.purple, .pink, .yellow, .red]
    
    init(selectedDate: Date, repository: MoodRepository, aiClient: YandexGPTClient) {
        self.selectedDate = selectedDate
        _viewModel = StateObject(wrappedValue: DayDetailViewModel(
            selectedDate: selectedDate,
            repository: repository,
            aiClient: aiClient
        ))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer
            contentOverlay
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundColor(.appPrimary)
                    .fontWeight(.semibold)
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    private var backgroundLayer: some View {
        ZStack {
            Color.black
            rotatingGradientLayer
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
    }
    
    private var contentOverlay: some View {
        ScrollView {
            VStack(spacing: 24) {
                dateHeader
                
                if (viewModel.record?.filledCount ?? 0) > 0 {
                    aiAdviceCard
                }
                
                moodSlotsSection
                Spacer().frame(height: 20)
            }
            .padding(20)
        }
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white.opacity(0.6))
                .shadow(color: .black.opacity(0.15), radius: 20, y: -10)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.appPrimary.opacity(0.1), lineWidth: 1)
                )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .ignoresSafeArea(edges: .bottom)
        .opacity(viewModel.isLoading ? 0 : 1)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isLoading)
    }
    
    private var aiAdviceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                    .font(.title3)
                Text("Совет на сегодня")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.appPrimary)
            }
            
            if viewModel.isAdviceLoading {
                HStack(spacing: 8) {
                    ProgressView().tint(.purple)
                    Text("Генерирую подсказку...")
                        .font(.subheadline)
                    
                        .foregroundColor(.appPrimary.opacity(0.6))
                    
                }
                .padding(.vertical, 4)
            } else {
                Text(viewModel.aiAdvice ?? "")
                   
                    .font(.body)
                    .foregroundColor(.appPrimary.opacity(0.85))
                    .lineSpacing(4)
                
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.06), Color.pink.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.15), lineWidth: 1)
            )
        )
        .cornerRadius(16)
        .navigationBarBackButtonHidden()
    }
    
    private var dateHeader: some View {
        VStack(spacing: 12) {
            Text(selectedDate, format: .dateTime.weekday(.wide))
                .font(.title3.weight(.semibold))
                .foregroundColor(.appPrimary.opacity(0.6))
            
            Text(selectedDate, format: .dateTime.day().month(.wide))
                .font(.title.weight(.bold))
                .foregroundColor(.appPrimary)
            
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            index < viewModel.filledCount
                            ? Color.green
                            : Color.appPrimary.opacity(0.15)
                        )
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 4)
        }
        .padding(.bottom, 8)
    }

    private var moodSlotsSection: some View {
        VStack(spacing: 14) {
            ForEach(MoodTimeSlot.allCases, id: \.self) { slot in
                MoodSlotRow(
                    slot: slot,
                    mood: viewModel.mood(for: slot),
                    time: slotTime(for: slot)
                )
            }
        }
    }

    private func slotTime(for slot: MoodTimeSlot) -> String {
        switch slot {
        case .morning: return "10:00"
        case .afternoon: return "16:00"
        case .evening: return "21:00"
        }
    }
}

private struct MoodSlotRow: View {
    let slot: MoodTimeSlot
    let mood: MoodType?
    let time: String
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: slot.icon)
                    .font(.title3)
                    .foregroundColor(.appPrimary.opacity(0.7))
                Text(time)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.appPrimary.opacity(0.5))
            }
            .frame(width: 50, alignment: .leading)
            
            if let mood = mood {
                HStack(spacing: 12) {
                    Text(mood.emoji)
                        .font(.system(size: 32))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(mood.label)
                            .font(.headline)
                            .foregroundColor(.appPrimary)
                        Text(slot.greeting.replacingOccurrences(of: "?", with: ""))
                            .font(.caption)
                            .foregroundColor(.appPrimary.opacity(0.6))
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(mood.accentColor.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(mood.accentColor.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                HStack {
                    Text("Not set")
                        .font(.subheadline)
                        .foregroundColor(.appPrimary.opacity(0.4))
                        .italic()
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appPrimary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.appPrimary.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
}
