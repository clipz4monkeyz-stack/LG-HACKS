//
//  Resource.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import Foundation

struct Resource: Identifiable, Codable {
    let id = UUID()
    var name: String
    var description: String
    var category: ResourceCategory
    var type: ResourceType
    var address: Address
    var contactInfo: ContactInfo
    var eligibilityRequirements: [String]
    var languagesSupported: [String]
    var isFree: Bool
    var cost: Double?
    var hours: [OperatingHours]
    var website: String?
    var rating: Double
    var reviewCount: Int
    var isVerified: Bool
    var lastUpdated: Date
    var distance: Double? // in miles
    var isBookmarked: Bool
    
    init(name: String, description: String, category: ResourceCategory, type: ResourceType, address: Address, contactInfo: ContactInfo) {
        self.name = name
        self.description = description
        self.category = category
        self.type = type
        self.address = address
        self.contactInfo = contactInfo
        self.eligibilityRequirements = []
        self.languagesSupported = []
        self.isFree = true
        self.cost = nil
        self.hours = []
        self.rating = 0.0
        self.reviewCount = 0
        self.isVerified = false
        self.lastUpdated = Date()
        self.isBookmarked = false
    }
}

enum ResourceCategory: String, CaseIterable, Codable {
    case healthcare = "Healthcare"
    case legal = "Legal Services"
    case housing = "Housing"
    case employment = "Employment"
    case education = "Education"
    case food = "Food Assistance"
    case transportation = "Transportation"
    case childcare = "Childcare"
    case mentalHealth = "Mental Health"
    case domesticViolence = "Domestic Violence"
    case immigration = "Immigration Services"
    case financial = "Financial Assistance"
    case translation = "Translation Services"
    case community = "Community Centers"
    case religious = "Religious Organizations"
    case other = "Other"
}

enum ResourceType: String, CaseIterable, Codable {
    case clinic = "Clinic"
    case hospital = "Hospital"
    case lawFirm = "Law Firm"
    case nonprofit = "Nonprofit Organization"
    case government = "Government Agency"
    case communityCenter = "Community Center"
    case foodBank = "Food Bank"
    case shelter = "Shelter"
    case school = "School"
    case library = "Library"
    case church = "Church"
    case mosque = "Mosque"
    case temple = "Temple"
    case other = "Other"
}

struct ContactInfo: Codable {
    var phone: String?
    var email: String?
    var website: String?
    var socialMedia: [String: String]?
    
    init(phone: String? = nil, email: String? = nil, website: String? = nil) {
        self.phone = phone
        self.email = email
        self.website = website
        self.socialMedia = nil
    }
}

struct OperatingHours: Codable {
    var dayOfWeek: DayOfWeek
    var openTime: String
    var closeTime: String
    var isClosed: Bool
    
    init(dayOfWeek: DayOfWeek, openTime: String, closeTime: String, isClosed: Bool = false) {
        self.dayOfWeek = dayOfWeek
        self.openTime = openTime
        self.closeTime = closeTime
        self.isClosed = isClosed
    }
}

enum DayOfWeek: String, CaseIterable, Codable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
}

struct ResourceReview: Identifiable, Codable {
    let id = UUID()
    var resourceId: UUID
    var userId: UUID
    var rating: Int // 1-5 stars
    var comment: String
    var createdAt: Date
    var isVerified: Bool
    
    init(resourceId: UUID, userId: UUID, rating: Int, comment: String) {
        self.resourceId = resourceId
        self.userId = userId
        self.rating = rating
        self.comment = comment
        self.createdAt = Date()
        self.isVerified = false
    }
}

struct EmergencyContact: Identifiable, Codable {
    let id = UUID()
    var name: String
    var phoneNumber: String
    var type: EmergencyContactType
    var isAvailable24_7: Bool
    var languages: [String]
    var description: String
    
    init(name: String, phoneNumber: String, type: EmergencyContactType, description: String) {
        self.name = name
        self.phoneNumber = phoneNumber
        self.type = type
        self.isAvailable24_7 = false
        self.languages = []
        self.description = description
    }
}

enum EmergencyContactType: String, CaseIterable, Codable {
    case police = "Police"
    case fire = "Fire Department"
    case medical = "Medical Emergency"
    case immigration = "Immigration Help"
    case domesticViolence = "Domestic Violence"
    case legal = "Legal Emergency"
    case mentalHealth = "Mental Health Crisis"
    case other = "Other"
}

struct RightsGuidance: Identifiable, Codable {
    let id = UUID()
    var scenario: String
    var situation: SituationType
    var guidance: [String]
    var doNotDo: [String]
    var emergencyActions: [String]
    var legalRights: [String]
    var contactNumbers: [String]
    var isUrgent: Bool
    var applicableVisaStatuses: [VisaStatus]
    
    init(scenario: String, situation: SituationType, guidance: [String]) {
        self.scenario = scenario
        self.situation = situation
        self.guidance = guidance
        self.doNotDo = []
        self.emergencyActions = []
        self.legalRights = []
        self.contactNumbers = []
        self.isUrgent = false
        self.applicableVisaStatuses = []
    }
}

enum SituationType: String, CaseIterable, Codable {
    case policeEncounter = "Police Encounter"
    case iceEncounter = "ICE Encounter"
    case workplaceRaid = "Workplace Raid"
    case homeRaid = "Home Raid"
    case trafficStop = "Traffic Stop"
    case borderCrossing = "Border Crossing"
    case detention = "Detention"
    case deportation = "Deportation"
    case domesticViolence = "Domestic Violence"
    case workplaceDiscrimination = "Workplace Discrimination"
    case housingDiscrimination = "Housing Discrimination"
    case medicalEmergency = "Medical Emergency"
    case other = "Other"
}
