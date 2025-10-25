//
//  WelcomeView.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var currentPage = 0
    
    private let pages = [
        WelcomePage(
            title: "Welcome to NavigateHome AI",
            subtitle: "Your Personal Immigration Caseworker",
            description: "NavigateHome AI is your 24/7 personal advocate, guiding you through legal paperwork, healthcare access, rights protection, and connecting you to verified community resources.",
            imageName: "house.fill",
            color: .blue
        ),
        WelcomePage(
            title: "Intelligent Document Assistant",
            subtitle: "Never Miss a Deadline",
            description: "Upload immigration forms and get step-by-step guidance in your native language. Our AI explains each question, flags common mistakes, and creates personalized checklists.",
            imageName: "doc.text.fill",
            color: .green
        ),
        WelcomePage(
            title: "Rights Protection",
            subtitle: "Know Your Rights, Stay Safe",
            description: "Get real-time guidance during police or ICE encounters. Learn what to say, what not to say, and how to protect yourself and your family.",
            imageName: "shield.fill",
            color: .red
        ),
        WelcomePage(
            title: "Healthcare Navigation",
            subtitle: "Access Care Without Fear",
            description: "Find free or low-cost healthcare clinics, understand your rights, and get help with medical forms and translations.",
            imageName: "cross.fill",
            color: .purple
        ),
        WelcomePage(
            title: "Community Resources",
            subtitle: "Connect to Verified Help",
            description: "Discover local resources for food, housing, employment, education, and legal services. All verified and immigrant-friendly.",
            imageName: "map.fill",
            color: .orange
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("NavigateHome AI")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Skip") {
                    dismiss()
                }
                .foregroundColor(.blue)
            }
            .padding()
            
            // Page Content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    WelcomePageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Page Indicator
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 20)
            
            // Navigation Buttons
            HStack {
                if currentPage > 0 {
                    Button("Previous") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .foregroundColor(.blue)
                } else {
                    Button("Get Started") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground))
    }
}

struct WelcomePage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let color: Color
}

struct WelcomePageView: View {
    let page: WelcomePage
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(page.color)
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.title2)
                    .foregroundColor(page.color)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    WelcomeView()
        .environmentObject(UserManager())
}
