//
//  ImmigrantUser.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import Foundation

struct ImmigrantUser: Identifiable, Codable {
    let id = UUID()
    var firstName: String
    var lastName: String
    var email: String
    var phoneNumber: String
    var preferredLanguage: String
    var nativeLanguage: String
    var currentVisaStatus: VisaStatus
    var countryOfOrigin: String
    var dateOfBirth: Date
    var emergencyContact: EmergencyContact
    var currentAddress: Address
    var familyMembers: [FamilyMember]
    var caseHistory: [CaseRecord]
    var documents: [Document]
    var createdAt: Date
    var lastActiveAt: Date
    
    init(firstName: String, lastName: String, email: String, phoneNumber: String, 
         preferredLanguage: String, nativeLanguage: String, currentVisaStatus: VisaStatus,
         countryOfOrigin: String, dateOfBirth: Date, emergencyContact: EmergencyContact,
         currentAddress: Address) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNumber = phoneNumber
        self.preferredLanguage = preferredLanguage
        self.nativeLanguage = nativeLanguage
        self.currentVisaStatus = currentVisaStatus
        self.countryOfOrigin = countryOfOrigin
        self.dateOfBirth = dateOfBirth
        self.emergencyContact = emergencyContact
        self.currentAddress = currentAddress
        self.familyMembers = []
        self.caseHistory = []
        self.documents = []
        self.createdAt = Date()
        self.lastActiveAt = Date()
    }
}

enum VisaStatus: String, CaseIterable, Codable {
    case tourist = "B-1/B-2 Tourist"
    case student = "F-1 Student"
    case work = "H-1B Work"
    case family = "Family-based"
    case asylum = "Asylum Seeker"
    case refugee = "Refugee"
    case daca = "DACA"
    case tps = "TPS"
    case greenCard = "Green Card Holder"
    case citizen = "US Citizen"
    case undocumented = "Undocumented"
    case other = "Other"
    
    var description: String {
        return self.rawValue
    }
    
    var hasWorkAuthorization: Bool {
        switch self {
        case .work, .greenCard, .citizen, .daca, .tps:
            return true
        default:
            return false
        }
    }
    
    var hasHealthcareAccess: Bool {
        switch self {
        case .greenCard, .citizen, .refugee, .asylum:
            return true
        default:
            return false
        }
    }
}


struct Address: Codable {
    var street: String
    var city: String
    var state: String
    var zipCode: String
    var country: String
    
    var fullAddress: String {
        return "\(street), \(city), \(state) \(zipCode), \(country)"
    }
}

struct FamilyMember: Identifiable, Codable {
    let id = UUID()
    var name: String
    var relationship: String
    var age: Int?
    var visaStatus: VisaStatus?
    var isUSCitizen: Bool
    var needsAssistance: Bool
}

struct CaseRecord: Identifiable, Codable {
    let id = UUID()
    var caseType: CaseType
    var status: CaseStatus
    var description: String
    var documents: [Document]
    var deadlines: [Deadline]
    var notes: [CaseNote]
    var createdAt: Date
    var lastUpdated: Date
    
    init(caseType: CaseType, description: String) {
        self.caseType = caseType
        self.status = .open
        self.description = description
        self.documents = []
        self.deadlines = []
        self.notes = []
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
}

enum CaseType: String, CaseIterable, Codable {
    case immigration = "Immigration"
    case healthcare = "Healthcare"
    case housing = "Housing"
    case employment = "Employment"
    case education = "Education"
    case legal = "Legal"
    case emergency = "Emergency"
    case other = "Other"
}

enum CaseStatus: String, CaseIterable, Codable {
    case open = "Open"
    case inProgress = "In Progress"
    case pending = "Pending"
    case completed = "Completed"
    case closed = "Closed"
    case urgent = "Urgent"
}

struct Deadline: Identifiable, Codable {
    let id = UUID()
    var title: String
    var dueDate: Date
    var priority: Priority
    var isCompleted: Bool
    var description: String?
    var reminderSent: Bool
    
    init(title: String, dueDate: Date, priority: Priority = .medium) {
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = false
        self.reminderSent = false
    }
}

enum Priority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    case critical = "Critical"
}

struct CaseNote: Identifiable, Codable {
    let id = UUID()
    var content: String
    var author: String
    var createdAt: Date
    var isPrivate: Bool
    
    init(content: String, author: String, isPrivate: Bool = false) {
        self.content = content
        self.author = author
        self.isPrivate = isPrivate
        self.createdAt = Date()
    }
}
