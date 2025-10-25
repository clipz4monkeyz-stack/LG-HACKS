//
//  TranslationService.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import Foundation

class TranslationService {
    
    func translateText(_ text: String, to language: String) async throws -> String {
        // In a real implementation, this would use Google Translate API, Azure Translator, or similar
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                // Mock translation - in real app, this would call translation API
                let translatedText = self.mockTranslate(text, to: language)
                continuation.resume(returning: translatedText)
            }
        }
    }
    
    func translateDocument(_ document: Data, to language: String) async throws -> String {
        // First extract text from document, then translate
        let documentAnalysisService = DocumentAnalysisService()
        let extractedText = try await documentAnalysisService.extractTextFromDocument(document)
        return try await translateText(extractedText, to: language)
    }
    
    func translateDocument(_ document: Data, from sourceLanguage: String, to targetLanguage: String) async throws -> String {
        // Similar to above but with source language specified
        let documentAnalysisService = DocumentAnalysisService()
        let extractedText = try await documentAnalysisService.extractTextFromDocument(document)
        return try await translateText(extractedText, to: targetLanguage)
    }
    
    func translateFormQuestion(_ question: String, to language: String) async throws -> String {
        // Specialized translation for form questions with context
        return try await translateText(question, to: language)
    }
    
    func translateEmergencyScript(_ script: [String], to language: String) async throws -> [String] {
        // Translate emergency scripts with cultural context
        var translatedScript: [String] = []
        
        for line in script {
            let translatedLine = try await translateText(line, to: language)
            translatedScript.append(translatedLine)
        }
        
        return translatedScript
    }
    
    func translateMedicalTerms(_ terms: [String], to language: String) async throws -> [String: String] {
        // Specialized medical translation with context
        var translatedTerms: [String: String] = [:]
        
        for term in terms {
            let translatedTerm = try await translateText(term, to: language)
            translatedTerms[term] = translatedTerm
        }
        
        return translatedTerms
    }
    
    func translateLegalTerms(_ terms: [String], to language: String) async throws -> [String: String] {
        // Specialized legal translation with context
        var translatedTerms: [String: String] = [:]
        
        for term in terms {
            let translatedTerm = try await translateText(term, to: language)
            translatedTerms[term] = translatedTerm
        }
        
        return translatedTerms
    }
    
    func detectLanguage(_ text: String) async throws -> String {
        // Language detection - in real implementation, use Google Cloud Translation or similar
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                // Mock language detection
                let detectedLanguage = self.mockDetectLanguage(text)
                continuation.resume(returning: detectedLanguage)
            }
        }
    }
    
    func getSupportedLanguages() -> [Language] {
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
    
    // MARK: - Mock Methods (Replace with real API calls)
    
    private func mockTranslate(_ text: String, to language: String) -> String {
        // Mock translation - in real implementation, this would call translation API
        let translations: [String: [String: String]] = [
            "es": [
                "What is your full legal name?": "¿Cuál es su nombre legal completo?",
                "What is your date of birth?": "¿Cuál es su fecha de nacimiento?",
                "What is your country of birth?": "¿Cuál es su país de nacimiento?",
                "You have the right to remain silent.": "Tiene derecho a permanecer en silencio.",
                "Do not sign anything without a lawyer.": "No firme nada sin un abogado."
            ],
            "zh": [
                "What is your full legal name?": "您的完整法定姓名是什么？",
                "What is your date of birth?": "您的出生日期是什么？",
                "What is your country of birth?": "您的出生国家是什么？",
                "You have the right to remain silent.": "您有权保持沉默。",
                "Do not sign anything without a lawyer.": "没有律师在场不要签署任何文件。"
            ],
            "ar": [
                "What is your full legal name?": "ما هو اسمك القانوني الكامل؟",
                "What is your date of birth?": "ما هو تاريخ ميلادك؟",
                "What is your country of birth?": "ما هي دولة ميلادك؟",
                "You have the right to remain silent.": "لديك الحق في التزام الصمت.",
                "Do not sign anything without a lawyer.": "لا توقع أي شيء بدون محام."
            ]
        ]
        
        return translations[language]?[text] ?? "[\(language)] \(text)"
    }
    
    private func mockDetectLanguage(_ text: String) -> String {
        // Simple language detection based on character patterns
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
}

