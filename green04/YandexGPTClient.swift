//
//  YandexGPTClient.swift
//  green04
//
//  Created by Karina Kazbekova on 13.04.2026.
//

import Foundation

struct YandexGPTClient {
    let apiKey: String
    let folderId: String
    private let baseURL = "https://llm.api.cloud.yandex.net/foundationModels/v1/completion"
    
    init(apiKey: String, folderId: String, source: String = "unknown") {
        let cleanApiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanFolderId = folderId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 🔍 Лог с source и stack trace
        print("🔐 [YandexGPTClient] source: '\(source)'")
        print("   apiKey: '\(cleanApiKey)' (count: \(cleanApiKey.count))")
        print("   folderId: '\(cleanFolderId)' (count: \(cleanFolderId.count))")
        
        // 🔍 Stack trace для отладки (только в DEBUG)
        #if DEBUG
        print("   📞 Call stack:")
        Thread.callStackSymbols.prefix(5).forEach { print("      \($0)") }
        #endif
        
        if cleanApiKey.isEmpty {
            fatalError("❌ API key empty. Source: '\(source)'. Passed: '\(apiKey)'")
        }
        if cleanFolderId.isEmpty {
            fatalError("❌ Folder ID empty. Source: '\(source)'. Passed: '\(folderId)'")
        }
        
        self.apiKey = cleanApiKey
        self.folderId = cleanFolderId
    }
    
    // ✅ Инициализатор без параметров — читает из Info.plist
    init() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "YandexAPIKey") as? String,
              let folderId = Bundle.main.object(forInfoDictionaryKey: "YandexFolderID") as? String else {
            fatalError("❌ Не найдены Yandex API credentials в Info.plist")
        }
        if apiKey.isEmpty || folderId.isEmpty {
            fatalError("❌ Yandex credentials в Info.plist пустые")
        }
        self.apiKey = apiKey
        self.folderId = folderId
    }
    
    func generateWellnessAdvice(
        morning: String?, afternoon: String?, evening: String?,
        date: Date
    ) async throws -> String {
        let dateString = date.formatted(date: .abbreviated, time: .omitted)
        
        let prompt = """
        Пользователь вел дневник настроения \(dateString).
        🌅 Утро: \(morning ?? "—")
        ☀️ День: \(afternoon ?? "—")
        🌙 Вечер: \(evening ?? "—")
        
        Дай один короткий, тёплый совет для хорошего самочувствия на русском (макс. 20 слов).
        Будь поддерживающим, не давай медицинских рекомендаций.
        """
        
        // 📦 Формируем тело запроса
        let body: [String: Any] = [
            "modelUri": "gpt://\(folderId)/yandexgpt/latest",
            "completionOptions": ["stream": false, "temperature": 0.8, "maxTokens": 200],
            "messages": [["role": "user", "text": prompt]]
        ]
        
        // 🔍 Отладка: печатаем запрос
        print("📤 Request to YandexGPT:")
        print("   modelUri: gpt://\(folderId)/yandexgpt/latest")
        print("   apiKey prefix: \(apiKey.prefix(min(10, apiKey.count)))...")
        if let jsonData = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("   body: \(jsonString)")
        }
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Api-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // 🌐 Отправляем запрос
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 🔍 Отладка: печатаем ответ
        print("📥 Response from YandexGPT:")
        if let httpResponse = response as? HTTPURLResponse {
            print("   Status Code: \(httpResponse.statusCode)")
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("   Raw body: \(responseString)")
        }
        
        // ✅ Проверяем статус
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse, userInfo: [
                NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)",
                "responseBody": String(data: data, encoding: .utf8) ?? ""
            ])
        }
        
        // 📦 Парсим ответ
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "YandexGPT", code: -2, userInfo: [NSLocalizedDescriptionKey: "Не удалось распарсить JSON"])
        }
        
        if let result = json["result"] as? [String: Any],
           let alternatives = result["alternatives"] as? [[String: Any]],
           let message = alternatives.first?["message"] as? [String: Any],
           let text = message["text"] as? String, !text.isEmpty {
            print("✅ Successfully parsed advice: \(text)")
            return text
        }
        
        // ❌ Если не удалось найти текст
        print("❌ Could not find 'text' in response. Full JSON:")
        print(json)
        
        throw NSError(
            domain: "YandexGPT",
            code: -1,
            userInfo: [
                NSLocalizedDescriptionKey: "Не удалось извлечь текст из ответа",
                "rawResponse": json
            ]
        )
    }
}
