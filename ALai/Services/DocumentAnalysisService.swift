//
//  DocumentAnalysisService.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import Foundation
import Vision
import PDFKit

class DocumentAnalysisService {
    
    func analyzeForm(_ formData: Data, formType: String) async throws -> FormAnalysisResult {
        // Simulate document analysis - in real implementation, this would use OCR and AI
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                let result = self.createMockFormAnalysis(formType: formType)
                continuation.resume(returning: result)
            }
        }
    }
    
    func extractTextFromDocument(_ documentData: Data) async throws -> String {
        // Extract text using Vision framework for OCR
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: DocumentAnalysisError.textRecognitionFailed)
                    return
                }
                
                let extractedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: extractedText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(data: documentData, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func identifyFormType(_ extractedText: String) -> String? {
        let formPatterns = [
            "I-485": "Application to Register Permanent Residence or Adjust Status",
            "I-130": "Petition for Alien Relative",
            "N-400": "Application for Naturalization",
            "I-765": "Application for Employment Authorization",
            "I-131": "Application for Travel Document",
            "I-90": "Application to Replace Permanent Resident Card",
            "I-751": "Petition to Remove Conditions on Residence",
            "I-864": "Affidavit of Support Under Section 213A of the Act"
        ]
        
        for (formNumber, description) in formPatterns {
            if extractedText.contains(formNumber) || extractedText.contains(description) {
                return formNumber
            }
        }
        
        return nil
    }
    
    func analyzeFormFields(_ extractedText: String, formType: String) -> [FormQuestion] {
        // This would use AI to identify form fields and create questions
        // For now, return mock data based on common form types
        return createMockQuestions(for: formType)
    }
    
    private func createMockFormAnalysis(formType: String) -> FormAnalysisResult {
        let questions = createMockQuestions(for: formType)
        
        return FormAnalysisResult(
            formType: formType,
            difficulty: .medium,
            estimatedTime: 90,
            requiredDocuments: [.passport, .birthCertificate, .marriageCertificate],
            commonMistakes: [
                "Leaving required fields blank",
                "Providing incorrect dates",
                "Missing supporting documents",
                "Incorrect fee amount"
            ],
            tips: [
                "Double-check all dates for accuracy",
                "Ensure all supporting documents are current",
                "Review instructions carefully before filling out",
                "Consider consulting with an immigration attorney for complex cases"
            ],
            questions: questions,
            warnings: [
                "This form requires careful attention to detail",
                "Missing information may result in rejection"
            ]
        )
    }
    
    private func createMockQuestions(for formType: String) -> [FormQuestion] {
        switch formType {
        case "I-485":
            return [
                FormQuestion(questionText: "What is your full legal name?", fieldName: "fullName", fieldType: .text),
                FormQuestion(questionText: "What is your date of birth?", fieldName: "dateOfBirth", fieldType: .date),
                FormQuestion(questionText: "What is your country of birth?", fieldName: "countryOfBirth", fieldType: .text),
                FormQuestion(questionText: "What is your current immigration status?", fieldName: "currentStatus", fieldType: .dropdown),
                FormQuestion(questionText: "Have you ever been arrested or convicted of a crime?", fieldName: "criminalHistory", fieldType: .checkbox)
            ]
        case "N-400":
            return [
                FormQuestion(questionText: "What is your full legal name?", fieldName: "fullName", fieldType: .text),
                FormQuestion(questionText: "What is your date of birth?", fieldName: "dateOfBirth", fieldType: .date),
                FormQuestion(questionText: "How long have you been a permanent resident?", fieldName: "residentYears", fieldType: .number),
                FormQuestion(questionText: "Can you read, write, and speak English?", fieldName: "englishAbility", fieldType: .checkbox),
                FormQuestion(questionText: "Are you willing to take the Oath of Allegiance?", fieldName: "oathWillingness", fieldType: .checkbox)
            ]
        default:
            return [
                FormQuestion(questionText: "What is your full legal name?", fieldName: "fullName", fieldType: .text),
                FormQuestion(questionText: "What is your date of birth?", fieldName: "dateOfBirth", fieldType: .date)
            ]
        }
    }
}

enum DocumentAnalysisError: Error {
    case textRecognitionFailed
    case formTypeNotIdentified
    case invalidDocumentFormat
    case analysisFailed
}
