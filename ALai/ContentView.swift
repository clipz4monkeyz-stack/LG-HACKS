//
//  ContentView.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var aiService = NavigateHomeAIService()
    @StateObject private var userManager = UserManager()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            EnhancedDashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            DocumentAssistantView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Forms")
                }
                .tag(1)

            RightsProtectionView()
                .tabItem {
                    Image(systemName: "shield.fill")
                    Text("Rights")
                }
                .tag(2)

            HealthcareView()
                .tabItem {
                    Image(systemName: "cross.fill")
                    Text("Health")
                }
                .tag(3)

            ResourcesView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Resources")
                }
                .tag(4)
        }
        .environmentObject(aiService)
        .environmentObject(userManager)
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
