//
//  ResourcesView.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct ResourcesView: View {
    @EnvironmentObject var aiService: NavigateHomeAIService
    @EnvironmentObject var userManager: UserManager
    @State private var selectedCategory: ResourceCategory = .legal
    @State private var resources: [Resource] = []
    @State private var isLoading = false
    @State private var showingResourceDetail: Resource?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Category Filter
                categoryFilter
                
                // Resources List
                if isLoading {
                    ProgressView("Finding resources...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if resources.isEmpty {
                    emptyStateView
                } else {
                    resourcesList
                }
            }
            .navigationTitle("Resources")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadResources()
            }
            .sheet(item: $showingResourceDetail) { resource in
                ResourceDetailView(resource: resource)
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search for resources...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    loadResources()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ResourceCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                        loadResources()
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No resources found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try selecting a different category or searching for specific services")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                loadResources()
            }) {
                Text("Show All Resources")
                    .foregroundColor(.blue)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var resourcesList: some View {
        List(resources) { resource in
            ResourceCard(resource: resource) {
                showingResourceDetail = resource
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func loadResources() {
        guard let user = userManager.currentUser else { return }
        
        isLoading = true
        
        Task {
            let foundResources = await aiService.findLocalResources(
                for: selectedCategory,
                location: user.currentAddress,
                userProfile: user
            )
            
            await MainActor.run {
                resources = foundResources ?? []
                isLoading = false
            }
        }
    }
}

struct CategoryChip: View {
    let category: ResourceCategory
    let isSelected: Bool
    let action: () -> Void
    
    private var icon: String {
        switch category {
        case .legal:
            return "scale.3d"
        case .healthcare:
            return "cross"
        case .housing:
            return "house"
        case .employment:
            return "briefcase"
        case .education:
            return "graduationcap"
        case .food:
            return "fork.knife"
        case .transportation:
            return "car"
        case .childcare:
            return "figure.and.child.holdinghands"
        case .mentalHealth:
            return "brain.head.profile"
        case .domesticViolence:
            return "exclamationmark.triangle"
        case .immigration:
            return "building.2"
        case .financial:
            return "dollarsign.circle"
        case .translation:
            return "globe"
        case .community:
            return "person.3"
        case .religious:
            return "cross.circle"
        case .other:
            return "ellipsis.circle"
        }
    }
    
    private var color: Color {
        switch category {
        case .legal:
            return .blue
        case .healthcare:
            return .green
        case .housing:
            return .orange
        case .employment:
            return .purple
        case .education:
            return .red
        case .food:
            return .yellow
        case .transportation:
            return .cyan
        case .childcare:
            return .pink
        case .mentalHealth:
            return .indigo
        case .domesticViolence:
            return .red
        case .immigration:
            return .blue
        case .financial:
            return .green
        case .translation:
            return .orange
        case .community:
            return .purple
        case .religious:
            return .brown
        case .other:
            return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ResourceCard: View {
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
                            .lineLimit(1)
                        
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
                        
                        if resource.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
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
                        
                        Text(resource.languagesSupported.prefix(2).joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        if resource.languagesSupported.count > 2 {
                            Text("+\(resource.languagesSupported.count - 2) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if resource.rating > 0 {
                    HStack {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(resource.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }
                        
                        Text("(\(resource.reviewCount))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
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

#Preview {
    ResourcesView()
        .environmentObject(NavigateHomeAIService())
        .environmentObject(UserManager())
}
