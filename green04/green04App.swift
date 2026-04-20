//
//  green04App.swift
//  green04
//
//  Created by Karina Kazbekova on 13.04.2026.
//

import SwiftUI

@main
struct green04App: App {
    @StateObject private var calendarVM: CalendarViewModel
    @StateObject private var scheduler: TimeSlotScheduler
    @State private var moodRingVM: MoodRingViewModel?
    @State private var isLoading = true
    
    // ✅ ОДИН раз объявляем свойство — без инициализации
    private let aiClient: YandexGPTClient
    
    // ✅ Инициализируем ВСЁ в init()
    init() {
        // 🔍 Читаем и чистим ключи
        let apiKey = (Bundle.main.object(forInfoDictionaryKey: "YandexAPIKey") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let folderId = (Bundle.main.object(forInfoDictionaryKey: "YandexFolderID") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 🔍 Отладка
        print("🔑 [init] API Key: '\(apiKey)' (count: \(apiKey.count))")
        print("📁 [init] Folder ID: '\(folderId)' (count: \(folderId.count))")
        
        // ✅ Инициализируем aiClient — ОДИН РАЗ
        self.aiClient = YandexGPTClient(apiKey: apiKey, folderId: folderId)
        
        // ✅ Остальные зависимости
        let calendarRepo = CalendarRepository()
        let calendarUseCase = GetDaysForMonthUseCase(repository: calendarRepo)
        _calendarVM = StateObject(wrappedValue: CalendarViewModel(useCase: calendarUseCase))
        _scheduler = StateObject(wrappedValue: TimeSlotScheduler())
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLoading {
                    AppLoadingView()
                        .transition(.opacity)
                } else {
                    mainContentView
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
            }
            .ignoresSafeArea()
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.4), value: isLoading)
            .onAppear {
                prepareAppForLaunch()
            }
        }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContentView: some View {
        ZStack {
            PeekableCalendarView(viewModel: calendarVM)
                .opacity(scheduler.shouldShowMoodRing ? 0.7 : 1)
                .disabled(scheduler.shouldShowMoodRing)
            
            if scheduler.shouldShowMoodRing, let slot = scheduler.activeSlot {
                moodRingOverlay(for: slot)
            }
        }
    }
    
    // MARK: - Overlay
    @ViewBuilder
    private func moodRingOverlay(for slot: TimeSlot) -> some View {
        if let vm = moodRingVM {
            MoodRingView(
                viewModel: vm,
                activeSlot: slot,
                isCatchUpMode: scheduler.isCatchUpMode,
                scheduler: scheduler,
                onAllCompleted: {
                    withAnimation(.easeOut(duration: 0.8)) {
                        scheduler.dismissMoodRing()
                    }
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.4))
            .ignoresSafeArea()
        }
    }
    
    @MainActor
    private func prepareAppForLaunch() {
        // 🔍 Тест: создаём клиент вручную (для отладки)
        #if DEBUG
        let testApiKey = ""
        let testFolderId = ""
        print("🧪 Testing direct init...")
        let testClient = YandexGPTClient(apiKey: testApiKey, folderId: testFolderId)
        print("🧪 Test client created! apiKey count: \(testClient.apiKey.count)")
        #endif
        
        setupMoodVM()
        
        let minimumDisplayTime: TimeInterval = 2.0
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(minimumDisplayTime * 1_000_000_000))
            
            let maxExtraWait: TimeInterval = 1.0
            let waitStart = Date()
            
            while !scheduler.isReady && Date().timeIntervalSince(waitStart) < maxExtraWait {
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
            
            withAnimation(.easeOut(duration: 0.4)) {
                isLoading = false
            }
        }
    }
    
    private func setupMoodVM() {
        guard moodRingVM == nil else { return }
        let moodRepo = UserDefaultsMoodRepository()
        let moodUseCase = SelectMoodUseCase(repository: moodRepo)
        let vm = MoodRingViewModel(selectMoodUseCase: moodUseCase, moodRepository: moodRepo)
        vm.scheduler = scheduler
        moodRingVM = vm
    }
}
