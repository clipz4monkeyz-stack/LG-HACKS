//
//  Document.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import Foundation

struct Document: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: DocumentType
    let status: DocumentStatus
    let isRequired: Bool
    let uploadDate: Date?
    let expirationDate: Date?
    let description: String?
    
    init(name: String, type: DocumentType, status: DocumentStatus, isRequired: Bool, uploadDate: Date? = nil, expirationDate: Date? = nil, description: String? = nil) {
        self.name = name
        self.type = type
        self.status = status
        self.isRequired = isRequired
        self.uploadDate = uploadDate
        self.expirationDate = expirationDate
        self.description = description
    }
}

enum DocumentType: String, CaseIterable, Codable {
    case passport = "Passport"
    case visa = "Visa"
    case greenCard = "Green Card"
    case birthCertificate = "Birth Certificate"
    case marriageCertificate = "Marriage Certificate"
    case divorceDecree = "Divorce Decree"
    case employmentAuthorization = "Employment Authorization"
    case socialSecurityCard = "Social Security Card"
    case driverLicense = "Driver's License"
    case medicalRecords = "Medical Records"
    case schoolTranscripts = "School Transcripts"
    case taxReturns = "Tax Returns"
    case bankStatements = "Bank Statements"
    case leaseAgreement = "Lease Agreement"
    case utilityBills = "Utility Bills"
    case immigrationForm = "Immigration Form"
    case courtDocuments = "Court Documents"
    case other = "Other"
}

enum DocumentStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case uploaded = "Uploaded"
    case underReview = "Under Review"
    case verified = "Verified"
    case rejected = "Rejected"
    case expired = "Expired"
    case completed = "Completed"
    case needsRenewal = "Needs Renewal"
}
