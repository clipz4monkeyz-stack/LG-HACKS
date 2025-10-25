//
//  DashboardView.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var aiService: NavigateHomeAIService
    @State private var showingWelcome = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Recent Cases
                    recentCasesSection
                    
                    // Upcoming Deadlines
                    deadlinesSection
                    
                    // Community Insights
                    communityInsightsSection
                    
                    // Emergency Contacts
                    emergencyContactsSection
                }
                .padding()
            }
            .navigationTitle("NavigateHome AI")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if userManager.currentUser?.caseHistory.isEmpty == true {
                    showingWelcome = true
                }
            }
            .sheet(isPresented: $showingWelcome) {
                WelcomeView()
            }
        }
    }
    
    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Welcome back,")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(userManager.currentUser?.firstName ?? "User")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Profile Image Placeholder
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(userManager.currentUser?.firstName.prefix(1) ?? "U"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            
            // Status Card
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("Status: \(userManager.currentUser?.currentVisaStatus.rawValue ?? "Unknown")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Last active: Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "Upload Form",
                    icon: "doc.badge.plus",
                    color: .blue,
                    action: { /* Navigate to document upload */ }
                )
                
                QuickActionCard(
                    title: "Find Resources",
                    icon: "map",
                    color: .green,
                    action: { /* Navigate to resources */ }
                )
                
                QuickActionCard(
                    title: "Emergency Help",
                    icon: "exclamationmark.triangle",
                    color: .red,
                    action: { /* Navigate to emergency */ }
                )
                
                QuickActionCard(
                    title: "Healthcare",
                    icon: "cross",
                    color: .purple,
                    action: { /* Navigate to healthcare */ }
                )
            }
        }
    }
    
    private var recentCasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Cases")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to cases
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if let cases = userManager.currentUser?.caseHistory, !cases.isEmpty {
                ForEach(cases.prefix(3)) { caseRecord in
                    CaseCard(caseRecord: caseRecord)
                }
            } else {
                Text("No recent cases")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
    
    private var deadlinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Deadlines")
                .font(.title2)
                .fontWeight(.bold)
            
            // Mock deadlines - in real app, these would come from user data
            DeadlineCard(
                title: "DACA Renewal",
                dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
                priority: .high
            )
            
            DeadlineCard(
                title: "Tax Filing",
                dueDate: Calendar.current.date(byAdding: .day, value: 45, to: Date()) ?? Date(),
                priority: .medium
            )
        }
    }
    
    private var communityInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community Insights")
                .font(.title2)
                .fontWeight(.bold)
            
            CommunityInsightCard(
                title: "DACA Renewal Success Rate",
                value: "94%",
                description: "Based on 1,247 recent applications in your area"
            )
            
            CommunityInsightCard(
                title: "Average Processing Time",
                value: "4-6 months",
                description: "For DACA renewals in California"
            )
        }
    }
    
    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Contacts")
                .font(.title2)
                .fontWeight(.bold)
            
            EmergencyContactCard(
                name: "Immigration Help Hotline",
                phone: "(555) 123-HELP",
                description: "24/7 Immigration assistance"
            )
            
            EmergencyContactCard(
                name: "Legal Aid Society",
                phone: "(555) 456-LEGAL",
                description: "Free legal help for immigrants"
            )
        }
    }
}

struct QuickActionCard: View {
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

struct CaseCard: View {
    let caseRecord: CaseRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(caseRecord.description)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(caseRecord.caseType.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Status: \(caseRecord.status.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DeadlineCard: View {
    let title: String
    let dueDate: Date
    let priority: Priority
    
    private var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }
    
    private var priorityColor: Color {
        switch priority {
        case .critical, .urgent:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .green
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text("Due: \(dueDate, style: .date)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(daysUntilDue) days remaining")
                    .font(.caption)
                    .foregroundColor(daysUntilDue < 7 ? .red : .secondary)
            }
            
            Spacer()
            
            Circle()
                .fill(priorityColor)
                .frame(width: 12, height: 12)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}


struct EmergencyContactCard: View {
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
                // Make phone call
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
    DashboardView()
        .environmentObject(UserManager())
        .environmentObject(NavigateHomeAIService())
}
