//
//  TideView.swift
//  ALai
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct TideView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var tideAPIService: TideAPIService
    @State private var tidePoints: [TidePoint] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showLocationSearch = false
    @State private var currentHeight: Double = 0
    
    private var toolbarTrailingPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #elseif os(macOS)
        return .primaryAction
        #endif
    }
    
    private var toolbarLeadingPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarLeading
        #elseif os(macOS)
        return .secondaryAction
        #endif
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let savedLocation = locationManager.savedLocation {
                    // Location header
                    locationHeader(savedLocation)
                    
                    if isLoading {
                        loadingView
                    } else if let errorMessage = errorMessage {
                        errorView(errorMessage)
                    } else if !tidePoints.isEmpty {
                        // Tide graph, table and summary
                        ScrollView {
                            VStack(spacing: 20) {
                                // Tide Graph (upper panel)
                                TideGraphView(tideData: TideGraphData(
                                    points: tidePoints,
                                    currentHeight: currentHeight,
                                    currentTime: Date()
                                ))
                                
                                // Tide Table
                                TideTableView(tideData: TideGraphData(
                                    points: tidePoints,
                                    currentHeight: currentHeight,
                                    currentTime: Date()
                                ))
                                
                                // Highs and Lows Summary
                                TideSummaryView(tideData: TideGraphData(
                                    points: tidePoints,
                                    currentHeight: currentHeight,
                                    currentTime: Date()
                                ))
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    } else {
                        emptyStateView
                    }
                } else {
                    // No location selected
                    noLocationView
                }
                
                Spacer()
            }
            .navigationTitle("Tide Times")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: toolbarTrailingPlacement) {
                    Button(action: {
                        showLocationSearch = true
                    }) {
                        Image(systemName: "location")
                    }
                }
                
                ToolbarItem(placement: toolbarLeadingPlacement) {
                    if locationManager.savedLocation != nil {
                        Button(action: {
                            locationManager.clearSavedLocation()
                            tidePoints = []
                            errorMessage = nil
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showLocationSearch) {
            LocationSearchView(
                locationManager: locationManager,
                tideAPIService: tideAPIService
            )
        }
        .onAppear {
            loadTideData()
        }
        .onChange(of: locationManager.savedLocation) { _, _ in
            loadTideData()
        }
        .refreshable {
            loadTideData()
        }
    }
    
    // MARK: - View Components
    
    private func locationHeader(_ location: UserLocation) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(location.stationName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let state = location.state {
                        Text(state)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Change") {
                    showLocationSearch = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading tide data...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.headline)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                loadTideData()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "wave.3.right")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No tide data available")
                .font(.headline)
            
            Text("Pull to refresh or check your location settings")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noLocationView: some View {
        VStack(spacing: 30) {
            Image(systemName: "location.circle")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.6))
            
            VStack(spacing: 12) {
                Text("Welcome to Tide Times")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Select a location to view tide predictions and charts")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Select Location") {
                showLocationSearch = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var tideDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tide Details")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                VStack {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(currentHeight, specifier: "%.1f") ft")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                VStack {
                    Text("High Tide")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let highTide = getNextTide(of: .high) {
                        Text("\(highTide.height, specifier: "%.1f") ft")
                            .font(.title2)
                            .fontWeight(.semibold)
                    } else {
                        Text("--")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                
                VStack {
                    Text("Low Tide")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let lowTide = getNextTide(of: .low) {
                        Text("\(lowTide.height, specifier: "%.1f") ft")
                            .font(.title2)
                            .fontWeight(.semibold)
                    } else {
                        Text("--")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var nextTidesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Tides")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(getUpcomingTides().prefix(4), id: \.time) { tide in
                    HStack {
                        Image(systemName: tide.type == .high ? "arrow.up" : "arrow.down")
                            .foregroundColor(tide.type == .high ? .red : .blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading) {
                            Text(tide.type.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(formatDate(tide.time))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(tide.height, specifier: "%.1f") ft")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadTideData() {
        guard let savedLocation = locationManager.savedLocation else { 
            print("No saved location found")
            return 
        }
        
        print("Loading tide data for station: \(savedLocation.stationId)")
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let points = try await tideAPIService.fetchTidePredictions(for: savedLocation.stationId)
                print("Loaded \(points.count) tide points")
                
                await MainActor.run {
                    tidePoints = points
                    currentHeight = calculateCurrentHeight()
                    isLoading = false
                    print("Current height calculated: \(currentHeight)")
                }
            } catch {
                print("Error loading tide data: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func calculateCurrentHeight() -> Double {
        let now = Date()
        
        // Find the two closest tide points to current time
        let sortedPoints = tidePoints.sorted { abs($0.time.timeIntervalSince(now)) < abs($1.time.timeIntervalSince(now)) }
        
        guard sortedPoints.count >= 2 else { return 0 }
        
        let closest = sortedPoints[0]
        let secondClosest = sortedPoints[1]
        
        // Simple linear interpolation between the two closest points
        let timeDiff = secondClosest.time.timeIntervalSince(closest.time)
        let heightDiff = secondClosest.height - closest.height
        let currentTimeDiff = now.timeIntervalSince(closest.time)
        
        return closest.height + (heightDiff * currentTimeDiff / timeDiff)
    }
    
    private func getNextTide(of type: TideType) -> TidePoint? {
        return tidePoints.first { tide in
            tide.time > Date() && tide.type == type
        }
    }
    
    private func getUpcomingTides() -> [TidePoint] {
        return tidePoints
            .filter { $0.time > Date() }
            .sorted { $0.time < $1.time }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    TideView(
        locationManager: LocationManager(),
        tideAPIService: TideAPIService()
    )
}
