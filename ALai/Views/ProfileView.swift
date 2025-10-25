//
//  ProfileView.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var showingCountryPicker = false
    @State private var editingProfile = false
    
    private let countries = [
        "Mexico", "China", "India", "Philippines", "El Salvador", "Guatemala",
        "Honduras", "Cuba", "Dominican Republic", "Colombia", "Brazil", "Venezuela",
        "Ecuador", "Peru", "Haiti", "Jamaica", "Nigeria", "Ethiopia", "Ghana",
        "Kenya", "Somalia", "Sudan", "Egypt", "Morocco", "Algeria", "Tunisia",
        "Libya", "Syria", "Iraq", "Afghanistan", "Pakistan", "Bangladesh",
        "Sri Lanka", "Nepal", "Myanmar", "Thailand", "Vietnam", "Cambodia",
        "Laos", "Indonesia", "Malaysia", "Singapore", "South Korea", "Japan",
        "Russia", "Ukraine", "Poland", "Romania", "Bulgaria", "Albania",
        "Bosnia", "Serbia", "Croatia", "Slovenia", "Slovakia", "Czech Republic",
        "Hungary", "Austria", "Germany", "France", "Italy", "Spain", "Portugal",
        "Greece", "Turkey", "Iran", "Saudi Arabia", "United Arab Emirates",
        "Israel", "Palestine", "Jordan", "Lebanon", "Yemen", "Oman", "Kuwait",
        "Qatar", "Bahrain", "Iraq", "Syria", "Afghanistan", "Pakistan"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Personal Information
                    personalInfoSection
                    
                    // Immigration Information
                    immigrationInfoSection
                    
                    // Contact Information
                    contactInfoSection
                    
                    // Emergency Contacts
                    emergencyContactsSection
                    
                    // Preferences
                    preferencesSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(editingProfile ? "Save" : "Edit") {
                        if editingProfile {
                            saveProfile()
                        }
                        editingProfile.toggle()
                    }
                }
            }
            .sheet(isPresented: $showingCountryPicker) {
                CountryPickerView(
                    countries: countries,
                    selectedCountry: Binding(
                        get: { userManager.currentUser?.countryOfOrigin ?? "" },
                        set: { userManager.currentUser?.countryOfOrigin = $0 }
                    )
                )
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Picture
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                )
            
            VStack(spacing: 4) {
                Text("\(userManager.currentUser?.firstName ?? "") \(userManager.currentUser?.lastName ?? "")")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(userManager.currentUser?.currentVisaStatus.rawValue ?? "Unknown Status")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Personal Information")
            
            VStack(spacing: 12) {
                ProfileField(
                    title: "First Name",
                    value: userManager.currentUser?.firstName ?? "",
                    isEditable: editingProfile
                )
                
                ProfileField(
                    title: "Last Name",
                    value: userManager.currentUser?.lastName ?? "",
                    isEditable: editingProfile
                )
                
                ProfileField(
                    title: "Date of Birth",
                    value: userManager.currentUser?.dateOfBirth.formatted(date: .abbreviated, time: .omitted) ?? "",
                    isEditable: editingProfile
                )
                
                ProfileField(
                    title: "Country of Origin",
                    value: userManager.currentUser?.countryOfOrigin ?? "",
                    isEditable: editingProfile,
                    action: { showingCountryPicker = true }
                )
            }
        }
    }
    
    private var immigrationInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Immigration Information")
            
            VStack(spacing: 12) {
                ProfileField(
                    title: "Visa Status",
                    value: userManager.currentUser?.currentVisaStatus.rawValue ?? "Unknown",
                    isEditable: false
                )
            }
        }
    }
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Contact Information")
            
            VStack(spacing: 12) {
                ProfileField(
                    title: "Email",
                    value: userManager.currentUser?.email ?? "",
                    isEditable: editingProfile
                )
                
                ProfileField(
                    title: "Phone",
                    value: userManager.currentUser?.phoneNumber ?? "",
                    isEditable: editingProfile
                )
                
                ProfileField(
                    title: "Address",
                    value: userManager.currentUser?.currentAddress.fullAddress ?? "",
                    isEditable: editingProfile
                )
            }
        }
    }
    
    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Emergency Contacts")
            
            if let contact = userManager.currentUser?.emergencyContact {
                EmergencyContactCard(
                    name: contact.name,
                    phone: contact.phoneNumber,
                    description: contact.description
                )
            } else {
                Text("No emergency contact added")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Preferences")
            
            VStack(spacing: 12) {
                ProfileField(
                    title: "Preferred Language",
                    value: userManager.currentUser?.preferredLanguage ?? "English",
                    isEditable: editingProfile
                )
                
                ProfileField(
                    title: "Notifications",
                    value: "Enabled",
                    isEditable: editingProfile
                )
            }
        }
    }
    
    private func saveProfile() {
        // Save profile changes
        // This would typically save to UserDefaults or a backend service
        userManager.saveUser()
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }
}

struct ProfileField: View {
    let title: String
    let value: String
    let isEditable: Bool
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if isEditable && action != nil {
                Button(action: action!) {
                    HStack {
                        Text(value.isEmpty ? "Tap to select" : value)
                            .foregroundColor(value.isEmpty ? .secondary : .primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Text(value.isEmpty ? "Not provided" : value)
                    .font(.subheadline)
                    .foregroundColor(value.isEmpty ? .secondary : .primary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}


struct CountryPickerView: View {
    let countries: [String]
    @Binding var selectedCountry: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(countries, id: \.self) { country in
                Button(action: {
                    selectedCountry = country
                    dismiss()
                }) {
                    HStack {
                        Text(country)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedCountry == country {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserManager())
}
