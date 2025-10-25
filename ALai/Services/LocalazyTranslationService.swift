//
//  LocalazyTranslationService.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import Foundation
import Combine

class LocalazyTranslationService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiKey = "YOUR_LOCALAZY_API_KEY" // Replace with actual API key
    private let baseURL = "https://api.localazy.com/v1"
    
    private var hasValidAPIKey: Bool {
        return !apiKey.isEmpty && apiKey != "YOUR_LOCALAZY_API_KEY"
    }
    
    func translateText(_ text: String, from sourceLanguage: String, to targetLanguage: String) async throws -> String {
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard hasValidAPIKey else {
            // Return mock translation for demo
            return getMockTranslation(text, to: targetLanguage)
        }
        
        let requestBody: [String: Any] = [
            "text": text,
            "source": sourceLanguage,
            "target": targetLanguage,
            "format": "text"
        ]
        
        guard let url = URL(string: "\(baseURL)/translate") else {
            throw TranslationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw TranslationError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TranslationError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let translatedText = json["translatedText"] as? String else {
            throw TranslationError.decodingError
        }
        
        return translatedText
    }
    
    func translateDocument(_ documentText: String, from sourceLanguage: String, to targetLanguage: String) async throws -> String {
        // Split long documents into chunks for translation
        let chunks = splitTextIntoChunks(documentText, maxLength: 1000)
        var translatedChunks: [String] = []
        
        for chunk in chunks {
            let translatedChunk = try await translateText(chunk, from: sourceLanguage, to: targetLanguage)
            translatedChunks.append(translatedChunk)
        }
        
        return translatedChunks.joined(separator: " ")
    }
    
    func detectLanguage(_ text: String) async throws -> String {
        guard hasValidAPIKey else {
            return mockDetectLanguage(text)
        }
        
        let requestBody: [String: Any] = [
            "text": text
        ]
        
        guard let url = URL(string: "\(baseURL)/detect") else {
            throw TranslationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw TranslationError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TranslationError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let detectedLanguage = json["language"] as? String else {
            throw TranslationError.decodingError
        }
        
        return detectedLanguage
    }
    
    func getSupportedLanguages() async throws -> [Language] {
        guard hasValidAPIKey else {
            return getMockSupportedLanguages()
        }
        
        guard let url = URL(string: "\(baseURL)/languages") else {
            throw TranslationError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TranslationError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let languagesData = json["languages"] as? [[String: Any]] else {
            throw TranslationError.decodingError
        }
        
        return languagesData.compactMap { languageData in
            guard let code = languageData["code"] as? String,
                  let name = languageData["name"] as? String else {
                return nil
            }
            return Language(code: code, name: name, nativeName: name)
        }
    }
    
    // MARK: - Helper Methods
    
    private func splitTextIntoChunks(_ text: String, maxLength: Int) -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var chunks: [String] = []
        var currentChunk = ""
        
        for word in words {
            if currentChunk.count + word.count + 1 <= maxLength {
                currentChunk += (currentChunk.isEmpty ? "" : " ") + word
            } else {
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk)
                }
                currentChunk = word
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        return chunks
    }
    
    private func getMockTranslation(_ text: String, to language: String) -> String {
        let translations: [String: [String: String]] = [
            "es": [
                "What is your full legal name?": "¿Cuál es su nombre legal completo?",
                "What is your date of birth?": "¿Cuál es su fecha de nacimiento?",
                "What is your country of birth?": "¿Cuál es su país de nacimiento?",
                "You have the right to remain silent.": "Tiene derecho a permanecer en silencio.",
                "Do not sign anything without a lawyer.": "No firme nada sin un abogado.",
                "I need help with my immigration case.": "Necesito ayuda con mi caso de inmigración.",
                "Where can I find free legal help?": "¿Dónde puedo encontrar ayuda legal gratuita?",
                "What documents do I need?": "¿Qué documentos necesito?"
            ],
            "zh": [
                "What is your full legal name?": "您的完整法定姓名是什么？",
                "What is your date of birth?": "您的出生日期是什么？",
                "What is your country of birth?": "您的出生国家是什么？",
                "You have the right to remain silent.": "您有权保持沉默。",
                "Do not sign anything without a lawyer.": "没有律师在场不要签署任何文件。",
                "I need help with my immigration case.": "我需要帮助处理我的移民案件。",
                "Where can I find free legal help?": "我在哪里可以找到免费的法律帮助？",
                "What documents do I need?": "我需要什么文件？"
            ],
            "ar": [
                "What is your full legal name?": "ما هو اسمك القانوني الكامل؟",
                "What is your date of birth?": "ما هو تاريخ ميلادك؟",
                "What is your country of birth?": "ما هي دولة ميلادك؟",
                "You have the right to remain silent.": "لديك الحق في التزام الصمت.",
                "Do not sign anything without a lawyer.": "لا توقع أي شيء بدون محام.",
                "I need help with my immigration case.": "أحتاج مساعدة في قضية الهجرة الخاصة بي.",
                "Where can I find free legal help?": "أين يمكنني العثور على مساعدة قانونية مجانية؟",
                "What documents do I need?": "ما هي الوثائق التي أحتاجها؟"
            ]
        ]
        
        return translations[language]?[text] ?? "[\(language)] \(text)"
    }
    
    private func mockDetectLanguage(_ text: String) -> String {
        if text.contains("¿") || text.contains("ñ") || text.contains("á") {
            return "es"
        } else if text.contains("的") || text.contains("是") || text.contains("什么") {
            return "zh"
        } else if text.contains("ما") || text.contains("هو") || text.contains("؟") {
            return "ar"
        } else {
            return "en"
        }
    }
    
    func getMockSupportedLanguages() -> [Language] {
        return [
            Language(code: "en", name: "English", nativeName: "English"),
            Language(code: "es", name: "Spanish", nativeName: "Español"),
            Language(code: "zh", name: "Chinese", nativeName: "中文"),
            Language(code: "ar", name: "Arabic", nativeName: "العربية"),
            Language(code: "hi", name: "Hindi", nativeName: "हिन्दी"),
            Language(code: "pt", name: "Portuguese", nativeName: "Português"),
            Language(code: "ru", name: "Russian", nativeName: "Русский"),
            Language(code: "ja", name: "Japanese", nativeName: "日本語"),
            Language(code: "ko", name: "Korean", nativeName: "한국어"),
            Language(code: "fr", name: "French", nativeName: "Français"),
            Language(code: "de", name: "German", nativeName: "Deutsch"),
            Language(code: "it", name: "Italian", nativeName: "Italiano"),
            Language(code: "vi", name: "Vietnamese", nativeName: "Tiếng Việt"),
            Language(code: "th", name: "Thai", nativeName: "ไทย"),
            Language(code: "ur", name: "Urdu", nativeName: "اردو"),
            Language(code: "fa", name: "Persian", nativeName: "فارسی"),
            Language(code: "tr", name: "Turkish", nativeName: "Türkçe"),
            Language(code: "pl", name: "Polish", nativeName: "Polski"),
            Language(code: "uk", name: "Ukrainian", nativeName: "Українська"),
            Language(code: "ro", name: "Romanian", nativeName: "Română")
        ]
    }
}

enum TranslationError: Error, LocalizedError {
    case invalidURL
    case encodingError
    case invalidResponse
    case decodingError
    case apiError(String)
    case noAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .encodingError:
            return "Failed to encode request"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to decode response"
        case .apiError(let message):
            return "API Error: \(message)"
        case .noAPIKey:
            return "Localazy API key not configured"
        }
    }
}
