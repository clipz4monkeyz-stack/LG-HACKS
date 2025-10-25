//
//  NavigateHomeAIService.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import Foundation
import SwiftUI
import Combine

class NavigateHomeAIService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let openAIService = OpenAIService()
    private let translationService = TranslationService()
    private let documentAnalysisService = DocumentAnalysisService()
    
    // MARK: - Document Analysis
    
    func analyzeImmigrationForm(_ formData: Data, formType: String) async -> FormAnalysisResult? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let analysis = try await documentAnalysisService.analyzeForm(formData, formType: formType)
            return analysis
        } catch {
            errorMessage = "Failed to analyze form: \(error.localizedDescription)"
            return nil
        }
    }
    
    func explainFormQuestion(_ question: String, in language: String) async -> String? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let explanation = try await openAIService.explainQuestion(question, language: language)
            return explanation
        } catch {
            errorMessage = "Failed to explain question: \(error.localizedDescription)"
            return nil
        }
    }
    
    func validateFormAnswers(_ answers: [String: String], formType: String) async -> ValidationResult? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let validation = try await openAIService.validateFormAnswers(answers, formType: formType)
            return validation
        } catch {
            errorMessage = "Failed to validate answers: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Rights Protection
    
    func getRightsGuidance(for situation: SituationType, visaStatus: VisaStatus) async -> RightsGuidance? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let guidance = try await openAIService.getRightsGuidance(situation: situation, visaStatus: visaStatus)
            return guidance
        } catch {
            errorMessage = "Failed to get rights guidance: \(error.localizedDescription)"
            return nil
        }
    }
    
    func generateEmergencyScript(for situation: SituationType, language: String) async -> [String]? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let script = try await openAIService.generateEmergencyScript(situation: situation, language: language)
            return script
        } catch {
            errorMessage = "Failed to generate emergency script: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Healthcare Navigation
    
    func findHealthcareResources(for condition: String, location: Address, language: String) async -> [Resource]? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let resources = try await openAIService.findHealthcareResources(condition: condition, location: location, language: language)
            return resources
        } catch {
            errorMessage = "Failed to find healthcare resources: \(error.localizedDescription)"
            return nil
        }
    }
    
    func translateMedicalDocument(_ document: Data, to language: String) async -> String? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let translation = try await translationService.translateDocument(document, to: language)
            return translation
        } catch {
            errorMessage = "Failed to translate medical document: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Resource Finding
    
    func findLocalResources(for category: ResourceCategory, location: Address, userProfile: ImmigrantUser) async -> [Resource]? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let resources = try await openAIService.findLocalResources(category: category, location: location, userProfile: userProfile)
            return resources
        } catch {
            errorMessage = "Failed to find local resources: \(error.localizedDescription)"
            return nil
        }
    }
    
    func checkEligibility(for resource: Resource, userProfile: ImmigrantUser) async -> EligibilityResult? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let eligibility = try await openAIService.checkEligibility(resource: resource, userProfile: userProfile)
            return eligibility
        } catch {
            errorMessage = "Failed to check eligibility: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Community Intelligence
    
    func getCommunityInsights(for formType: String, userProfile: ImmigrantUser) async -> CommunityInsights? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let insights = try await openAIService.getCommunityInsights(formType: formType, userProfile: userProfile)
            return insights
        } catch {
            errorMessage = "Failed to get community insights: \(error.localizedDescription)"
            return nil
        }
    }
    
    func reportScam(_ scamInfo: ScamReport) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let success = try await openAIService.reportScam(scamInfo)
            return success
        } catch {
            errorMessage = "Failed to report scam: \(error.localizedDescription)"
            return false
        }
    }
    
    // MARK: - Translation
    
    func translateText(_ text: String, to language: String) async -> String? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let translation = try await translationService.translateText(text, to: language)
            return translation
        } catch {
            errorMessage = "Failed to translate text: \(error.localizedDescription)"
            return nil
        }
    }
    
    func translateDocument(_ document: Data, from sourceLanguage: String, to targetLanguage: String) async -> String? {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let translation = try await translationService.translateDocument(document, from: sourceLanguage, to: targetLanguage)
            return translation
        } catch {
            errorMessage = "Failed to translate document: \(error.localizedDescription)"
            return nil
        }
    }
}

// MARK: - Supporting Types

struct FormAnalysisResult: Codable {
    var formType: String
    var difficulty: DifficultyLevel
    var estimatedTime: Int
    var requiredDocuments: [DocumentType]
    var commonMistakes: [String]
    var tips: [String]
    var questions: [FormQuestion]
    var warnings: [String]
}

struct ValidationResult: Codable {
    var isValid: Bool
    var errors: [ValidationError]
    var warnings: [String]
    var suggestions: [String]
}

struct ValidationError: Codable {
    var field: String
    var message: String
    var severity: ErrorSeverity
}

enum ErrorSeverity: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

struct EligibilityResult: Codable {
    var isEligible: Bool
    var requirements: [String]
    var missingRequirements: [String]
    var nextSteps: [String]
    var alternativeResources: [Resource]
}

struct CommunityInsights: Codable {
    var successRate: Double
    var commonIssues: [String]
    var tips: [String]
    var averageProcessingTime: String
    var recommendedDocuments: [DocumentType]
    var warnings: [String]
}

struct ScamReport: Codable {
    var companyName: String
    var contactInfo: String
    var description: String
    var amountLost: Double?
    var reportedBy: UUID
    var dateReported: Date
}
