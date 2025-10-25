//
//  UserManager.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import Foundation
import SwiftUI
import Combine

class UserManager: ObservableObject {
    @Published var currentUser: ImmigrantUser?
    @Published var isLoggedIn = false
    @Published var isLoading = false
    
    init() {
        // Load user from UserDefaults or create demo user
        loadUser()
    }
    
    func login(email: String, password: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate login - in real app, this would authenticate with backend
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        // For demo purposes, create a sample user
        let sampleUser = createSampleUser()
        currentUser = sampleUser
        isLoggedIn = true
        saveUser()
        
        return true
    }
    
    func register(user: ImmigrantUser) async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate registration
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        currentUser = user
        isLoggedIn = true
        saveUser()
        
        return true
    }
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    func updateUser(_ user: ImmigrantUser) {
        currentUser = user
        saveUser()
    }
    
    func addCase(_ caseRecord: CaseRecord) {
        guard var user = currentUser else { return }
        user.caseHistory.append(caseRecord)
        currentUser = user
        saveUser()
    }
    
    func updateCase(_ caseRecord: CaseRecord) {
        guard var user = currentUser else { return }
        if let index = user.caseHistory.firstIndex(where: { $0.id == caseRecord.id }) {
            user.caseHistory[index] = caseRecord
            currentUser = user
            saveUser()
        }
    }
    
    func addDocument(_ document: Document) {
        guard var user = currentUser else { return }
        user.documents.append(document)
        currentUser = user
        saveUser()
    }
    
    func updateDocument(_ document: Document) {
        guard var user = currentUser else { return }
        if let index = user.documents.firstIndex(where: { $0.id == document.id }) {
            user.documents[index] = document
            currentUser = user
            saveUser()
        }
    }
    
    private func loadUser() {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(ImmigrantUser.self, from: data) {
            currentUser = user
            isLoggedIn = true
        } else {
            // Create demo user for first-time users
            currentUser = createSampleUser()
            isLoggedIn = true
            saveUser()
        }
    }
    
    func saveUser() {
        if let user = currentUser,
           let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "currentUser")
        }
    }
    
    private func createSampleUser() -> ImmigrantUser {
        let emergencyContact = EmergencyContact(
            name: "Maria Rodriguez",
            phoneNumber: "(555) 123-4567",
            type: .other,
            description: "Sister - Emergency Contact"
        )
        
        let address = Address(
            street: "456 Oak Avenue",
            city: "Los Angeles",
            state: "CA",
            zipCode: "90210",
            country: "USA"
        )
        
        let user = ImmigrantUser(
            firstName: "Carlos",
            lastName: "Rodriguez",
            email: "carlos@email.com",
            phoneNumber: "(555) 987-6543",
            preferredLanguage: "Spanish",
            nativeLanguage: "Spanish",
            currentVisaStatus: .daca,
            countryOfOrigin: "Mexico",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
            emergencyContact: emergencyContact,
            currentAddress: address
        )
        
        // Add some sample data
        var sampleUser = user
        sampleUser.familyMembers = [
            FamilyMember(name: "Maria Rodriguez", relationship: "Sister", age: 28, visaStatus: .greenCard, isUSCitizen: false, needsAssistance: false),
            FamilyMember(name: "Ana Rodriguez", relationship: "Mother", age: 55, visaStatus: .undocumented, isUSCitizen: false, needsAssistance: true)
        ]
        
        sampleUser.caseHistory = [
            CaseRecord(caseType: .immigration, description: "DACA Renewal Application"),
            CaseRecord(caseType: .healthcare, description: "Finding healthcare for mother")
        ]
        
        sampleUser.documents = [
            Document(name: "Passport", type: .passport, status: .pending, isRequired: true),
            Document(name: "DACA Card", type: .employmentAuthorization, status: .verified, isRequired: true),
            Document(name: "Birth Certificate", type: .birthCertificate, status: .pending, isRequired: true)
        ]
        
        return sampleUser
    }
}
