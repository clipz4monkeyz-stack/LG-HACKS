//
//  OpenAIService.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 10/5/25.
//

import Foundation
import Combine

class OpenAIService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiKey = "sk-proj-placeholder" // This will be replaced with actual key or use mock data
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    private var hasValidAPIKey: Bool {
        return !apiKey.isEmpty && apiKey != "YOUR_OPENAI_API_KEY" && !apiKey.contains("placeholder")
    }
    
    // MARK: - Form Analysis and Guidance
    
    func explainQuestion(_ question: String, language: String) async throws -> String {
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard hasValidAPIKey else {
            return getMockQuestionExplanation(question, language: language)
        }
        
        let prompt = createQuestionExplanationPrompt(question, language: language)
        return try await makeAPICall(prompt: prompt)
    }
    
    func validateFormAnswers(_ answers: [String: String], formType: String) async throws -> ValidationResult {
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard hasValidAPIKey else {
            return getMockValidationResult(answers, formType: formType)
        }
        
        let prompt = createValidationPrompt(answers, formType: formType)
        let response = try await makeAPICall(prompt: prompt)
        
        // Parse the response into ValidationResult
        return parseValidationResult(response)
    }
    
    // MARK: - Rights Protection
    
    func getRightsGuidance(situation: SituationType, visaStatus: VisaStatus) async throws -> RightsGuidance {
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard hasValidAPIKey else {
            return getMockRightsGuidance(situation: situation, visaStatus: visaStatus)
        }
        
        let prompt = createRightsGuidancePrompt(situation: situation, visaStatus: visaStatus)
        let response = try await makeAPICall(prompt: prompt)
        
        return parseRightsGuidance(response, situation: situation)
    }
    
    func generateEmergencyScript(situation: SituationType, language: String) async throws -> [String] {
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard hasValidAPIKey else {
            return getMockEmergencyScript(situation: situation, language: language)
        }
        
        let prompt = createEmergencyScriptPrompt(situation: situation, language: language)
        let response = try await makeAPICall(prompt: prompt)
        
        return parseEmergencyScript(response)
    }
    
    // MARK: - Healthcare Navigation
    
    func findHealthcareResources(condition: String, location: Address, language: String) async throws -> [Resource] {
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard hasValidAPIKey else {
            return getMockHealthcareResources(condition: condition, location: location, language: language)
        }
        
        let prompt = createHealthcareResourcesPrompt(condition: condition, location: location, language: language)
        let response = try await makeAPICall(prompt: prompt)
        
        return parseResources(response)
    }
    
    // MARK: - Resource Finding
    
    func findLocalResources(category: ResourceCategory, location: Address, userProfile: ImmigrantUser) async throws -> [Resource] {
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard hasValidAPIKey else {
            return getMockLocalResources(category: category, location: location, userProfile: userProfile)
        }
        
        let prompt = createLocalResourcesPrompt(category: category, location: location, userProfile: userProfile)
        let response = try await makeAPICall(prompt: prompt)
        
        return parseResources(response)
    }
    
    func checkEligibility(resource: Resource, userProfile: ImmigrantUser) async throws -> EligibilityResult {
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard hasValidAPIKey else {
            return getMockEligibilityResult(resource: resource, userProfile: userProfile)
        }
        
        let prompt = createEligibilityPrompt(resource: resource, userProfile: userProfile)
        let response = try await makeAPICall(prompt: prompt)
        
        return parseEligibilityResult(response)
    }
    
    // MARK: - Community Intelligence
    
    func getCommunityInsights(formType: String, userProfile: ImmigrantUser) async throws -> CommunityInsights {
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard hasValidAPIKey else {
            return getMockCommunityInsights(formType: formType, userProfile: userProfile)
        }
        
        let prompt = createCommunityInsightsPrompt(formType: formType, userProfile: userProfile)
        let response = try await makeAPICall(prompt: prompt)
        
        return parseCommunityInsights(response)
    }
    
    func reportScam(_ scamInfo: ScamReport) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        // Always return true for scam reporting - this should be logged regardless of API key
        return true
    }
    
    // MARK: - Private Helper Methods
    
    private func makeAPICall(prompt: String) async throws -> String {
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                [
                    "role": "system",
                    "content": "You are NavigateHome AI, a compassionate and knowledgeable personal caseworker for immigrants. Provide accurate, helpful, and culturally sensitive guidance. Always prioritize user safety and legal compliance."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 1000,
            "temperature": 0.3
        ]
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? [String: Any],
               let message = errorMessage["message"] as? String {
                throw OpenAIError.apiError(message)
            } else {
                throw OpenAIError.apiError("HTTP \(httpResponse.statusCode)")
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.decodingError
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Prompt Creation Methods
    
    private func createQuestionExplanationPrompt(_ question: String, language: String) -> String {
        return """
        Explain this immigration form question in simple, clear language in \(language):
        
        Question: "\(question)"
        
        Please provide:
        1. What the question is asking in plain language
        2. Why this information is needed
        3. How to answer it correctly
        4. Common mistakes to avoid
        5. What documents might be needed to support the answer
        
        Keep the explanation culturally sensitive and easy to understand.
        """
    }
    
    private func createValidationPrompt(_ answers: [String: String], formType: String) -> String {
        let answersText = answers.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        
        return """
        Validate these immigration form answers for \(formType):
        
        Answers:
        \(answersText)
        
        Please check for:
        1. Required fields that are missing
        2. Incorrect formats (dates, phone numbers, etc.)
        3. Inconsistent information
        4. Common mistakes that lead to rejection
        
        Return validation results in JSON format with errors, warnings, and suggestions.
        """
    }
    
    private func createRightsGuidancePrompt(situation: SituationType, visaStatus: VisaStatus) -> String {
        return """
        Provide rights guidance for this situation:
        
        Situation: \(situation.rawValue)
        Visa Status: \(visaStatus.rawValue)
        
        Please provide:
        1. What rights apply in this situation
        2. What to do step by step
        3. What NOT to do
        4. Emergency contact numbers
        5. Legal protections available
        
        Focus on immediate safety and legal compliance.
        """
    }
    
    private func createEmergencyScriptPrompt(situation: SituationType, language: String) -> String {
        return """
        Generate an emergency script for this situation in \(language):
        
        Situation: \(situation.rawValue)
        
        Provide short, clear phrases the person can say, including:
        1. Right to remain silent
        2. Request for lawyer
        3. Request for interpreter
        4. Emergency contact information
        
        Keep phrases simple and easy to remember under stress.
        """
    }
    
    private func createHealthcareResourcesPrompt(condition: String, location: Address, language: String) -> String {
            return """
        Find healthcare resources for this condition in \(location.city), \(location.state):
        
        Condition: \(condition)
        Location: \(location.fullAddress)
        Language: \(language)
        
        Please find:
        1. Free or low-cost clinics
        2. Hospitals with interpreter services
        3. Community health centers
        4. Emergency services
        5. Specialized care if needed
        
        Focus on resources that don't require documentation or insurance.
        """
    }
    
    private func createLocalResourcesPrompt(category: ResourceCategory, location: Address, userProfile: ImmigrantUser) -> String {
        return """
        Find \(category.rawValue) resources in \(location.city), \(location.state) for:
        
        User Profile:
        - Visa Status: \(userProfile.currentVisaStatus.rawValue)
        - Language: \(userProfile.preferredLanguage)
        - Country of Origin: \(userProfile.countryOfOrigin)
        
        Please find verified, legitimate resources that:
        1. Serve immigrants
        2. Provide services in \(userProfile.preferredLanguage)
        3. Don't require extensive documentation
        4. Are free or low-cost
        5. Have good community reputation
        
        Include contact information and eligibility requirements.
        """
    }
    
    private func createEligibilityPrompt(resource: Resource, userProfile: ImmigrantUser) -> String {
            return """
        Check eligibility for this resource:
        
        Resource: \(resource.name)
        Category: \(resource.category.rawValue)
        Requirements: \(resource.eligibilityRequirements.joined(separator: ", "))
        
        User Profile:
        - Visa Status: \(userProfile.currentVisaStatus.rawValue)
        - Country of Origin: \(userProfile.countryOfOrigin)
        - Family Members: \(userProfile.familyMembers.count)
        
        Determine:
        1. Is the user eligible?
        2. What requirements are missing?
        3. What are the next steps?
        4. Alternative resources if not eligible
        """
    }
    
    private func createCommunityInsightsPrompt(formType: String, userProfile: ImmigrantUser) -> String {
        return """
        Provide community insights for \(formType) applications:
        
        User Profile:
        - Visa Status: \(userProfile.currentVisaStatus.rawValue)
        - Country of Origin: \(userProfile.countryOfOrigin)
        - Language: \(userProfile.preferredLanguage)
        
        Based on community data, provide:
        1. Success rate for similar cases
        2. Common issues and how to avoid them
        3. Recommended documents to include
        4. Average processing time
        5. Tips from successful applicants
        6. Warnings about scams or unreliable services
        """
    }
    
    // MARK: - Mock Data Methods
    
    private func getMockQuestionExplanation(_ question: String, language: String) -> String {
            return """
        **Question Explanation (\(language)):**
        
        This question is asking for your basic personal information. It's required by immigration law to verify your identity and eligibility.
        
        **Why it's needed:** Immigration officials need to confirm who you are and that you meet the requirements for this application.
        
        **How to answer:** Provide your complete legal name exactly as it appears on your official documents (passport, birth certificate, etc.).
        
        **Common mistakes to avoid:**
        - Using nicknames instead of legal names
        - Inconsistent spelling
        - Missing middle names when required
        
        **Supporting documents:** You'll need your passport, birth certificate, or other official ID documents.
        """
    }
    
    private func getMockValidationResult(_ answers: [String: String], formType: String) -> ValidationResult {
        return ValidationResult(
            isValid: true,
            errors: [],
            warnings: ["Double-check all dates for accuracy"],
            suggestions: ["Consider having a lawyer review before submission"]
        )
    }
    
    private func getMockRightsGuidance(situation: SituationType, visaStatus: VisaStatus) -> RightsGuidance {
        return RightsGuidance(
            scenario: "Police encounter",
            situation: situation,
            guidance: [
                "Stay calm and respectful",
                "You have the right to remain silent",
                "Ask for a lawyer if questioned",
                "Don't sign anything without understanding it"
            ]
        )
    }
    
    private func getMockEmergencyScript(situation: SituationType, language: String) -> [String] {
        switch language {
        case "es":
            return [
                "Tengo derecho a permanecer en silencio.",
                "Quiero hablar con un abogado.",
                "No entiendo inglés, necesito un intérprete.",
                "No voy a firmar nada sin mi abogado."
            ]
        case "zh":
            return [
                "我有权保持沉默。",
                "我想和律师谈话。",
                "我不懂英语，需要翻译。",
                "没有律师我不会签署任何文件。"
            ]
        default:
            return [
                "I have the right to remain silent.",
                "I want to speak with a lawyer.",
                "I don't understand English, I need an interpreter.",
                "I will not sign anything without my lawyer."
            ]
        }
    }
    
    private func getMockHealthcareResources(condition: String, location: Address, language: String) -> [Resource] {
        return [
            Resource(
                name: "Community Health Center",
                description: "Free healthcare for immigrants",
                category: .healthcare,
                type: .clinic,
                address: location,
                contactInfo: ContactInfo(phone: "(555) 123-4567")
            )
        ]
    }
    
    private func getMockLocalResources(category: ResourceCategory, location: Address, userProfile: ImmigrantUser) -> [Resource] {
        return [
            Resource(
                name: "Local \(category.rawValue) Center",
                description: "Services for immigrants in \(userProfile.preferredLanguage)",
                category: category,
                type: .communityCenter,
                address: location,
                contactInfo: ContactInfo(phone: "(555) 987-6543")
            )
        ]
    }
    
    private func getMockEligibilityResult(resource: Resource, userProfile: ImmigrantUser) -> EligibilityResult {
        return EligibilityResult(
            isEligible: true,
            requirements: ["Valid ID", "Proof of income"],
            missingRequirements: [],
            nextSteps: ["Call to schedule appointment", "Bring required documents"],
            alternativeResources: []
        )
    }
    
    private func getMockCommunityInsights(formType: String, userProfile: ImmigrantUser) -> CommunityInsights {
        return CommunityInsights(
            successRate: 0.85,
            commonIssues: ["Missing documents", "Incorrect fees"],
            tips: ["Submit early", "Double-check all information"],
            averageProcessingTime: "6-12 months",
            recommendedDocuments: [.passport, .birthCertificate],
            warnings: ["Avoid notarios", "Use official USCIS forms only"]
        )
    }
    
    // MARK: - Parsing Methods
    
    private func parseValidationResult(_ response: String) -> ValidationResult {
        // Parse AI response into ValidationResult
        return ValidationResult(isValid: true, errors: [], warnings: [], suggestions: [])
    }
    
    private func parseRightsGuidance(_ response: String, situation: SituationType) -> RightsGuidance {
        // Parse AI response into RightsGuidance
        return RightsGuidance(scenario: response, situation: situation, guidance: [])
    }
    
    private func parseEmergencyScript(_ response: String) -> [String] {
        // Parse AI response into emergency script array
        return response.components(separatedBy: "\n").filter { !$0.isEmpty }
    }
    
    private func parseResources(_ response: String) -> [Resource] {
        // Parse AI response into Resource array
        return []
    }
    
    private func parseEligibilityResult(_ response: String) -> EligibilityResult {
        // Parse AI response into EligibilityResult
        return EligibilityResult(isEligible: true, requirements: [], missingRequirements: [], nextSteps: [], alternativeResources: [])
    }
    
    private func parseCommunityInsights(_ response: String) -> CommunityInsights {
        // Parse AI response into CommunityInsights
        return CommunityInsights(successRate: 0.0, commonIssues: [], tips: [], averageProcessingTime: "", recommendedDocuments: [], warnings: [])
    }
}

enum OpenAIError: Error, LocalizedError {
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
            return "OpenAI API key not configured"
        }
    }
}