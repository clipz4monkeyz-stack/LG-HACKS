//
//  RightsProtectionView.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct RightsProtectionView: View {
    @EnvironmentObject var aiService: NavigateHomeAIService
    @EnvironmentObject var userManager: UserManager
    @State private var selectedSituation: SituationType?
    @State private var rightsGuidance: RightsGuidance?
    @State private var emergencyScript: [String] = []
    @State private var showingEmergencyMode = false
    @State private var isGeneratingGuidance = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Emergency Mode Toggle
                    emergencyModeSection
                    
                    // Situation Selector
                    situationSelectorSection
                    
                    // Rights Guidance
                    if let guidance = rightsGuidance {
                        rightsGuidanceSection(guidance)
                    }
                    
                    // Emergency Script
                    if !emergencyScript.isEmpty {
                        emergencyScriptSection
                    }
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Emergency Contacts
                    emergencyContactsSection
                }
                .padding()
            }
            .navigationTitle("Rights Protection")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var emergencyModeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                
                Text("Emergency Mode")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Toggle("", isOn: $showingEmergencyMode)
                    .toggleStyle(SwitchToggleStyle(tint: .red))
            }
            
            if showingEmergencyMode {
                VStack(spacing: 8) {
                    Text("Emergency mode provides immediate, simplified guidance for urgent situations.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        // Call emergency number
                        if let url = URL(string: "tel:911") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Call 911")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var situationSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's happening?")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(SituationType.allCases, id: \.self) { situation in
                    SituationCard(situation: situation, isSelected: selectedSituation == situation) {
                        selectedSituation = situation
                        generateRightsGuidance(for: situation)
                    }
                }
            }
        }
    }
    
    private func rightsGuidanceSection(_ guidance: RightsGuidance) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Rights & What To Do")
                .font(.title2)
                .fontWeight(.bold)
            
            // Legal Rights
            if !guidance.legalRights.isEmpty {
                RightsCard(
                    title: "Your Legal Rights",
                    icon: "scale.3d",
                    color: .blue,
                    items: guidance.legalRights
                )
            }
            
            // What To Do
            if !guidance.guidance.isEmpty {
                RightsCard(
                    title: "What To Do",
                    icon: "checkmark.circle",
                    color: .green,
                    items: guidance.guidance
                )
            }
            
            // What NOT To Do
            if !guidance.doNotDo.isEmpty {
                RightsCard(
                    title: "What NOT To Do",
                    icon: "xmark.circle",
                    color: .red,
                    items: guidance.doNotDo
                )
            }
            
            // Emergency Actions
            if !guidance.emergencyActions.isEmpty {
                RightsCard(
                    title: "Emergency Actions",
                    icon: "exclamationmark.triangle",
                    color: .orange,
                    items: guidance.emergencyActions
                )
            }
        }
    }
    
    private var emergencyScriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Script")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Memorize these phrases. Say them calmly and clearly:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(Array(emergencyScript.enumerated()), id: \.offset) { index, phrase in
                EmergencyPhraseCard(phrase: phrase, number: index + 1)
            }
            
            Button(action: {
                // Practice mode - could play audio or show pronunciation
            }) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Practice Pronunciation")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Record Interaction",
                    icon: "mic.fill",
                    color: .red
                ) {
                    // Start recording
                }
                
                QuickActionButton(
                    title: "Find Lawyer",
                    icon: "person.badge.shield.checkmark",
                    color: .blue
                ) {
                    // Find nearby lawyers
                }
                
                QuickActionButton(
                    title: "Contact Family",
                    icon: "phone.fill",
                    color: .green
                ) {
                    // Call emergency contact
                }
                
                QuickActionButton(
                    title: "Document Evidence",
                    icon: "camera.fill",
                    color: .purple
                ) {
                    // Take photos/videos
                }
            }
        }
    }
    
    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Contacts")
                .font(.title2)
                .fontWeight(.bold)
            
            EmergencyContactRow(
                name: "Immigration Help Hotline",
                phone: "(555) 123-HELP",
                description: "24/7 Immigration assistance"
            )
            
            EmergencyContactRow(
                name: "Legal Aid Society",
                phone: "(555) 456-LEGAL",
                description: "Free legal help for immigrants"
            )
            
            EmergencyContactRow(
                name: "ACLU Immigrants' Rights",
                phone: "(555) 789-RIGHTS",
                description: "Constitutional rights protection"
            )
        }
    }
    
    private func generateRightsGuidance(for situation: SituationType) {
        guard let user = userManager.currentUser else { return }
        
        isGeneratingGuidance = true
        
        Task {
            let guidance = await aiService.getRightsGuidance(for: situation, visaStatus: user.currentVisaStatus)
            let script = await aiService.generateEmergencyScript(for: situation, language: user.preferredLanguage)
            
            await MainActor.run {
                rightsGuidance = guidance
                emergencyScript = script ?? []
                isGeneratingGuidance = false
            }
        }
    }
}

struct SituationCard: View {
    let situation: SituationType
    let isSelected: Bool
    let onTap: () -> Void
    
    private var icon: String {
        switch situation {
        case .policeEncounter:
            return "person.badge.shield.checkmark"
        case .iceEncounter:
            return "building.2"
        case .workplaceRaid:
            return "building"
        case .homeRaid:
            return "house"
        case .trafficStop:
            return "car"
        case .borderCrossing:
            return "map"
        case .detention:
            return "lock"
        case .deportation:
            return "airplane"
        case .domesticViolence:
            return "exclamationmark.triangle"
        case .workplaceDiscrimination:
            return "person.2"
        case .housingDiscrimination:
            return "house.lodge"
        case .medicalEmergency:
            return "cross"
        case .other:
            return "questionmark.circle"
        }
    }
    
    private var color: Color {
        switch situation {
        case .policeEncounter, .iceEncounter, .workplaceRaid, .homeRaid:
            return .red
        case .trafficStop, .borderCrossing:
            return .orange
        case .detention, .deportation:
            return .purple
        case .domesticViolence:
            return .red
        case .workplaceDiscrimination, .housingDiscrimination:
            return .blue
        case .medicalEmergency:
            return .green
        case .other:
            return .gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
                
                Text(situation.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? color : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RightsCard: View {
    let title: String
    let icon: String
    let color: Color
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(color)
                        .font(.caption)
                    
                    Text(item)
                        .font(.subheadline)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmergencyPhraseCard: View {
    let phrase: String
    let number: Int
    
    var body: some View {
        HStack {
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .cornerRadius(15)
            
            Text(phrase)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Button(action: {
                // Play audio or show pronunciation
            }) {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmergencyContactRow: View {
    let name: String
    let phone: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                
                Text(phone)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                if let url = URL(string: "tel:\(phone)") {
                    UIApplication.shared.open(url)
                }
            }) {
                Image(systemName: "phone.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    RightsProtectionView()
        .environmentObject(NavigateHomeAIService())
        .environmentObject(UserManager())
}
