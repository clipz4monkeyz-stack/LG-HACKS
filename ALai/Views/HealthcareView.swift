//
//  HealthcareView.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct HealthcareView: View {
    @EnvironmentObject var aiService: NavigateHomeAIService
    @EnvironmentObject var userManager: UserManager
    @State private var searchText = ""
    @State private var selectedCategory: HealthcareCategory = .general
    @State private var healthcareResources: [Resource] = []
    @State private var isSearching = false
    @State private var showingResourceDetail: Resource?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Section
                searchSection
                
                // Category Filter
                categoryFilterSection
                
                // Resources List
                if isSearching {
                    ProgressView("Finding healthcare resources...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if healthcareResources.isEmpty {
                    emptyStateView
                } else {
                    resourcesListView
                }
            }
            .navigationTitle("Healthcare")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadHealthcareResources()
            }
            .sheet(item: $showingResourceDetail) { resource in
                ResourceDetailView(resource: resource)
            }
        }
    }
    
    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search for healthcare services...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        loadHealthcareResources()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            Button(action: {
                searchHealthcareResources()
            }) {
                HStack {
                    Image(systemName: "cross.fill")
                    Text("Find Healthcare")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(searchText.isEmpty)
        }
        .padding()
    }
    
    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HealthcareCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        filterResourcesByCategory()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cross.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No healthcare resources found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try searching for a specific condition or service")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                loadHealthcareResources()
            }) {
                Text("Show All Resources")
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var resourcesListView: some View {
        List(healthcareResources) { resource in
            HealthcareResourceCard(resource: resource) {
                showingResourceDetail = resource
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func loadHealthcareResources() {
        guard let user = userManager.currentUser else { return }
        
        // Mock healthcare resources - in real app, these would come from API
        healthcareResources = [
            Resource(
                name: "Community Health Center",
                description: "Free healthcare for immigrants and low-income families",
                category: .healthcare,
                type: .clinic,
                address: user.currentAddress,
                contactInfo: ContactInfo(phone: "(555) 123-4567", website: "https://communityhealth.org")
            ),
            Resource(
                name: "Free Medical Clinic",
                description: "No insurance required, multilingual staff",
                category: .healthcare,
                type: .clinic,
                address: user.currentAddress,
                contactInfo: ContactInfo(phone: "(555) 234-5678")
            ),
            Resource(
                name: "Immigrant Health Services",
                description: "Specialized healthcare for immigrants",
                category: .healthcare,
                type: .nonprofit,
                address: user.currentAddress,
                contactInfo: ContactInfo(phone: "(555) 345-6789")
            )
        ]
    }
    
    private func searchHealthcareResources() {
        guard !searchText.isEmpty, let user = userManager.currentUser else { return }
        
        isSearching = true
        
        Task {
            let resources = await aiService.findHealthcareResources(
                for: searchText,
                location: user.currentAddress,
                language: user.preferredLanguage
            )
            
            await MainActor.run {
                healthcareResources = resources ?? []
                isSearching = false
            }
        }
    }
    
    private func filterResourcesByCategory() {
        // Filter resources based on selected category
        // This would be implemented based on the specific category requirements
    }
}

enum HealthcareCategory: String, CaseIterable {
    case general = "General"
    case emergency = "Emergency"
    case mentalHealth = "Mental Health"
    case dental = "Dental"
    case vision = "Vision"
    case women = "Women's Health"
    case children = "Children's Health"
    case seniors = "Senior Care"
    case chronic = "Chronic Conditions"
    case preventive = "Preventive Care"
}

struct CategoryButton: View {
    let category: HealthcareCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HealthcareResourceCard: View {
    let resource: Resource
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(resource.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(resource.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if resource.isFree {
                            Text("FREE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Label(resource.address.city, systemImage: "location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let phone = resource.contactInfo.phone {
                        Label(phone, systemImage: "phone")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                if !resource.languagesSupported.isEmpty {
                    HStack {
                        Text("Languages:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(resource.languagesSupported.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ResourceDetailView: View {
    let resource: Resource
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(resource.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(resource.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if resource.isFree {
                            Text("FREE")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact Information")
                            .font(.headline)
                        
                        if let phone = resource.contactInfo.phone {
                            ContactRow(icon: "phone.fill", text: phone, action: {
                                if let url = URL(string: "tel:\(phone)") {
                                    UIApplication.shared.open(url)
                                }
                            })
                        }
                        
                        if let email = resource.contactInfo.email {
                            ContactRow(icon: "envelope.fill", text: email, action: {
                                if let url = URL(string: "mailto:\(email)") {
                                    UIApplication.shared.open(url)
                                }
                            })
                        }
                        
                        if let website = resource.contactInfo.website {
                            ContactRow(icon: "globe", text: website, action: {
                                if let url = URL(string: website) {
                                    UIApplication.shared.open(url)
                                }
                            })
                        }
                    }
                    
                    // Address
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Address")
                            .font(.headline)
                        
                        Text(resource.address.fullAddress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Languages Supported
                    if !resource.languagesSupported.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Languages Supported")
                                .font(.headline)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                ForEach(resource.languagesSupported, id: \.self) { language in
                                    Text(language)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Eligibility Requirements
                    if !resource.eligibilityRequirements.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Eligibility Requirements")
                                .font(.headline)
                            
                            ForEach(resource.eligibilityRequirements, id: \.self) { requirement in
                                HStack(alignment: .top) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                    
                                    Text(requirement)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            // Call the resource
                            if let phone = resource.contactInfo.phone,
                               let url = URL(string: "tel:\(phone)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "phone.fill")
                                Text("Call Now")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            // Get directions
                            let address = resource.address.fullAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                            if let url = URL(string: "http://maps.apple.com/?q=\(address)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Get Directions")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Resource Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ContactRow: View {
    let icon: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HealthcareView()
        .environmentObject(NavigateHomeAIService())
        .environmentObject(UserManager())
}
