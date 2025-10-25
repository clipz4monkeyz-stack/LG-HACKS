//
//  EnhancedDashboardView.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct EnhancedDashboardView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var aiService: NavigateHomeAIService
    @StateObject private var translationService = LocalazyTranslationService()
    @State private var selectedLanguage: Language = Language(code: "en", name: "English", nativeName: "English")
    @State private var showingLanguagePicker = false
    @State private var showingProfile = false
    @State private var showingChatbot = false
    @State private var chatbotMessage = ""
    @State private var showingWelcome = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top Header with Translation and Profile
                headerSection
                
                // Main Dashboard Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Documents Section - Pending and Completed
                        documentsSection
                        
                        // Quick Actions
                        quickActionsSection
                        
                        // Recent Activity
                        recentActivitySection
                        
                        // Community Insights
                        communityInsightsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("NewHome.AI")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if userManager.currentUser?.caseHistory.isEmpty == true {
                    showingWelcome = true
                }
            }
            .sheet(isPresented: $showingLanguagePicker) {
                LanguagePickerView(selectedLanguage: $selectedLanguage)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingChatbot) {
                ChatbotView()
            }
            .sheet(isPresented: $showingWelcome) {
                WelcomeView()
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            // Language Dropdown
            Button(action: {
                showingLanguagePicker = true
            }) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                    Text(selectedLanguage.nativeName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            Spacer()
            
            // Profile Button
            Button(action: {
                showingProfile = true
            }) {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Documents")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                // Pending Documents
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Pending")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Spacer()
                        Text("\(pendingDocuments.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(12)
                    }
                    
                    if pendingDocuments.isEmpty {
                        Text("No pending documents")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    } else {
                        ForEach(pendingDocuments.prefix(3)) { document in
                            DocumentCard(document: document, isCompleted: false)
                        }
                        
                        if pendingDocuments.count > 3 {
                            Button("View All Pending (\(pendingDocuments.count))") {
                                // Navigate to pending documents view
                            }
                            .font(.caption)
                            .foregroundColor(.orange)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Completed Documents
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Completed")
                            .font(.headline)
                            .foregroundColor(.green)
                        Spacer()
                        Text("\(completedDocuments.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                    }
                    
                    if completedDocuments.isEmpty {
                        Text("No completed documents")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    } else {
                        ForEach(completedDocuments.prefix(3)) { document in
                            DocumentCard(document: document, isCompleted: true)
                        }
                        
                        if completedDocuments.count > 3 {
                            Button("View All Completed (\(completedDocuments.count))") {
                                // Navigate to completed documents view
                            }
                            .font(.caption)
                            .foregroundColor(.green)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
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
                QuickActionCard(
                    title: "Ask AI Assistant",
                    icon: "message.fill",
                    color: .blue,
                    action: { showingChatbot = true }
                )
                
                QuickActionCard(
                    title: "Upload Document",
                    icon: "doc.badge.plus",
                    color: .green,
                    action: { /* Navigate to document upload */ }
                )
                
                QuickActionCard(
                    title: "Find Resources",
                    icon: "map.fill",
                    color: .purple,
                    action: { /* Navigate to resources */ }
                )
                
                QuickActionCard(
                    title: "Emergency Help",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    action: { /* Navigate to emergency */ }
                )
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.bold)
            
            if let cases = userManager.currentUser?.caseHistory, !cases.isEmpty {
                ForEach(cases.prefix(3)) { caseRecord in
                    ActivityCard(caseRecord: caseRecord)
                }
            } else {
                Text("No recent activity")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
    
    private var communityInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community Insights")
                .font(.title2)
                .fontWeight(.bold)
            
            CommunityInsightCard(
                title: "Success Rate",
                value: "94%",
                description: "Based on 1,247 recent applications"
            )
            
            CommunityInsightCard(
                title: "Average Time",
                value: "4-6 months",
                description: "For your visa type in your area"
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var pendingDocuments: [Document] {
        userManager.currentUser?.documents.filter { $0.status != .verified && $0.status != .completed } ?? []
    }
    
    private var completedDocuments: [Document] {
        userManager.currentUser?.documents.filter { $0.status == .verified || $0.status == .completed } ?? []
    }
}

struct DocumentCard: View {
    let document: Document
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(document.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if document.isRequired {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActivityCard: View {
    let caseRecord: CaseRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(caseRecord.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(caseRecord.caseType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Updated \(caseRecord.lastUpdated, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: caseRecord.status)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct StatusBadge: View {
    let status: CaseStatus
    
    private var color: Color {
        switch status {
        case .open, .inProgress:
            return .blue
        case .pending:
            return .orange
        case .completed:
            return .green
        case .closed:
            return .gray
        case .urgent:
            return .red
        }
    }
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct CommunityInsightCard: View {
    let title: String
    let value: String
    let description: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chart.bar.fill")
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    EnhancedDashboardView()
        .environmentObject(UserManager())
        .environmentObject(NavigateHomeAIService())
}
