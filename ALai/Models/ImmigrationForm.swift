//
//  ImmigrationForm.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import Foundation

struct ImmigrationForm: Identifiable, Codable {
    let id = UUID()
    var formNumber: String
    var title: String
    var description: String
    var category: FormCategory
    var difficulty: DifficultyLevel
    var estimatedTime: Int // in minutes
    var requiredDocuments: [DocumentType]
    var commonMistakes: [String]
    var tips: [String]
    var deadline: Date?
    var filingFee: Double?
    var isEligible: Bool
    var eligibilityCriteria: [String]
    var userProgress: FormProgress?
    
    init(formNumber: String, title: String, description: String, category: FormCategory) {
        self.formNumber = formNumber
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = .medium
        self.estimatedTime = 60
        self.requiredDocuments = []
        self.commonMistakes = []
        self.tips = []
        self.filingFee = nil
        self.isEligible = false
        self.eligibilityCriteria = []
    }
}

enum FormCategory: String, CaseIterable, Codable {
    case adjustmentOfStatus = "Adjustment of Status"
    case familyPetition = "Family Petition"
    case naturalization = "Naturalization"
    case workAuthorization = "Work Authorization"
    case travelDocument = "Travel Document"
    case renewal = "Renewal"
    case changeOfStatus = "Change of Status"
    case asylum = "Asylum"
    case refugee = "Refugee"
    case other = "Other"
}

enum DifficultyLevel: String, CaseIterable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"
}

struct FormProgress: Codable {
    var currentStep: Int
    var totalSteps: Int
    var completedSections: [String]
    var answers: [String: AnyCodable]
    var uploadedDocuments: [String]
    var lastSaved: Date
    var isSubmitted: Bool
    
    init(totalSteps: Int) {
        self.currentStep = 1
        self.totalSteps = totalSteps
        self.completedSections = []
        self.answers = [:]
        self.uploadedDocuments = []
        self.lastSaved = Date()
        self.isSubmitted = false
    }
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

struct FormQuestion: Identifiable, Codable {
    let id = UUID()
    var questionText: String
    var translatedText: String?
    var fieldName: String
    var fieldType: FieldType
    var isRequired: Bool
    var options: [String]?
    var helpText: String?
    var validationRules: [ValidationRule]
    var userAnswer: String?
    
    init(questionText: String, fieldName: String, fieldType: FieldType, isRequired: Bool = true) {
        self.questionText = questionText
        self.fieldName = fieldName
        self.fieldType = fieldType
        self.isRequired = isRequired
        self.validationRules = []
    }
}

enum FieldType: String, CaseIterable, Codable {
    case text = "Text"
    case number = "Number"
    case date = "Date"
    case email = "Email"
    case phone = "Phone"
    case address = "Address"
    case checkbox = "Checkbox"
    case radio = "Radio"
    case dropdown = "Dropdown"
    case file = "File"
    case signature = "Signature"
}

struct ValidationRule: Codable {
    var type: ValidationType
    var message: String
    var value: String?
    
    init(type: ValidationType, message: String, value: String? = nil) {
        self.type = type
        self.message = message
        self.value = value
    }
}

enum ValidationType: String, CaseIterable, Codable {
    case required = "Required"
    case minLength = "Minimum Length"
    case maxLength = "Maximum Length"
    case email = "Email Format"
    case phone = "Phone Format"
    case date = "Date Format"
    case number = "Number Format"
    case custom = "Custom"
}
