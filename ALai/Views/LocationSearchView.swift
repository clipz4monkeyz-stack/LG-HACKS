//
//  LocationSearchView.swift
//  ALai
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI
import CoreLocation

struct LocationSearchView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var tideAPIService: TideAPIService
    @State private var searchText = ""
    @State private var searchResults: [TideStation] = []
    @State private var isSearching = false
    @State private var showCurrentLocation = true
    @Environment(\.dismiss) private var dismiss
    
    private var isLocationAuthorized: Bool {
        #if os(iOS)
        return locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways
        #elseif os(macOS)
        return locationManager.authorizationStatus == .authorizedAlways
        #endif
    }
    
    private var toolbarCancelPlacement: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #elseif os(macOS)
        return .cancellationAction
        #endif
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search for a location", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchText) { _, newValue in
                            performSearch(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                            searchResults = []
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Current location option
                if showCurrentLocation && isLocationAuthorized {
                    Button(action: {
                        useCurrentLocation()
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text("Use Current Location")
                                .foregroundColor(.primary)
                            Spacer()
                            if locationManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .disabled(locationManager.isLoading)
                }
                
                // Search results
                if isSearching {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Searching...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if !searchResults.isEmpty {
                    List(searchResults) { station in
                        LocationRowView(station: station) {
                            selectLocation(station)
                        }
                    }
                    .listStyle(PlainListStyle())
                } else if !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No locations found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Try searching for a city or state")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "location.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.6))
                        
                        Text("Find Your Tide Station")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Search for a location to view tide predictions")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if !isLocationAuthorized {
                            Button("Enable Location Access") {
                                locationManager.requestLocationPermission()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Spacer()
            }
            .navigationTitle("Select Location")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: toolbarCancelPlacement) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestLocationPermission()
            }
        }
    }
    
    // MARK: - Actions
    
    private func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task {
            do {
                let results = try await tideAPIService.searchStations(query: query)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
    
    private func selectLocation(_ station: TideStation) {
        let userLocation = UserLocation(
            stationId: station.id,
            stationName: station.name,
            latitude: station.latitude,
            longitude: station.longitude,
            state: station.state
        )
        
        locationManager.saveLocation(userLocation)
        dismiss()
    }
    
    private func useCurrentLocation() {
        locationManager.requestCurrentLocation()
        
        // In a real app, you'd wait for the location and then find the nearest station
        // For now, we'll use a default station
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let defaultStation = TideStation(
                id: "9414290",
                name: "San Francisco, CA",
                state: "CA",
                latitude: 37.8067,
                longitude: -122.4653
            )
            selectLocation(defaultStation)
        }
    }
}

struct LocationRowView: View {
    let station: TideStation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(station.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let state = station.state {
                        Text(state)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LocationSearchView(
        locationManager: LocationManager(),
        tideAPIService: TideAPIService()
    )
}
