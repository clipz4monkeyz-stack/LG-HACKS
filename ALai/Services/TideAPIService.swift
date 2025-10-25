//
//  TideAPIService.swift
//  ALai
//
//  Created by Anwen Li on 9/24/25.
//

import Foundation
import CoreLocation
import Combine

class TideAPIService: ObservableObject {
    private let baseURL = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter"
    
    // MARK: - Public Methods
    
    func fetchTideStations(near location: CLLocation) async throws -> [TideStation] {
        let urlString = "\(baseURL)?product=water_level&application=NOS.COOPS.TAC.WL&begin_date=\(getCurrentDateString())&end_date=\(getCurrentDateString())&datum=MLLW&station=\(getNearestStationId(for: location))&time_zone=gmt&units=metric&interval=h&format=json"
        
        guard let url = URL(string: urlString) else {
            throw TideAPIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // For now, we'll use a simplified approach and return predefined stations
        // In a real app, you'd parse the actual API response
        return getNearbyStations(for: location)
    }
    
    func fetchTidePredictions(for stationId: String, days: Int = 2) async throws -> [TidePoint] {
        // For demonstration purposes, return mock data
        // In a production app, you would use the real NOAA API
        return generateMockTideData(for: stationId)
    }
    
    private func generateMockTideData(for stationId: String) -> [TidePoint] {
        let now = Date()
        var tidePoints: [TidePoint] = []
        
        // Generate 24 hours of tide data (every hour)
        for i in 0..<24 {
            let time = now.addingTimeInterval(TimeInterval(i * 3600)) // Add hours
            let hour = Calendar.current.component(.hour, from: time)
            
            // Create a realistic tide pattern
            // High tides around 6 AM/PM, low tides around 12 AM/PM
            let baseHeight = 2.5
            let amplitude = 1.8
            let phase = Double(hour) * .pi / 12.0 // 12-hour cycle
            let height = baseHeight + amplitude * sin(phase)
            
            // Determine if this is a high or low tide
            let tideType: TideType = (hour % 12 == 6 || hour % 12 == 18) ? .high : 
                                   (hour % 12 == 0 || hour % 12 == 12) ? .low : 
                                   (height > baseHeight + 1.0) ? .high : .low
            
            let tidePoint = TidePoint(
                time: time,
                height: height,
                type: tideType
            )
            
            tidePoints.append(tidePoint)
        }
        
        return tidePoints
    }
    
    func searchStations(query: String) async throws -> [TideStation] {
        // Simulate API search - in reality, you'd use a proper search endpoint
        let allStations = getAllStations()
        
        let filtered = allStations.filter { station in
            station.name.localizedCaseInsensitiveContains(query) ||
            (station.state?.localizedCaseInsensitiveContains(query) ?? false)
        }
        
        return Array(filtered.prefix(10)) // Limit to 10 results
    }
    
    // MARK: - Private Methods
    
    private func processTidePredictions(_ predictions: [TidePrediction]) -> [TidePoint] {
        let sortedPredictions = predictions.sorted { $0.time < $1.time }
        var tidePoints: [TidePoint] = []
        
        for i in 0..<sortedPredictions.count {
            let prediction = sortedPredictions[i]
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            guard let date = formatter.date(from: prediction.time) else { continue }
            
            // Determine if this is a high or low tide based on surrounding values
            let tideType = determineTideType(predictions: sortedPredictions, index: i)
            
            let tidePoint = TidePoint(
                time: date,
                height: prediction.height,
                type: tideType
            )
            
            tidePoints.append(tidePoint)
        }
        
        return tidePoints
    }
    
    private func determineTideType(predictions: [TidePrediction], index: Int) -> TideType {
        let currentHeight = predictions[index].height
        
        // Simple heuristic: compare with neighbors
        let windowSize = 3
        let startIndex = max(0, index - windowSize)
        let endIndex = min(predictions.count - 1, index + windowSize)
        
        let neighbors = predictions[startIndex...endIndex].map { $0.height }
        let maxNeighbor = neighbors.max() ?? currentHeight
        let minNeighbor = neighbors.min() ?? currentHeight
        
        // If current height is close to max, it's likely a high tide
        if abs(currentHeight - maxNeighbor) < 0.1 {
            return .high
        } else if abs(currentHeight - minNeighbor) < 0.1 {
            return .low
        }
        
        // Default to high for simplicity
        return .high
    }
    
    private func getCurrentDateString() -> String {
        return formatDate(Date())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
    
    private func getNearestStationId(for location: CLLocation) -> String {
        // Return a default station ID - in reality, you'd find the nearest one
        return "9414290" // San Francisco, CA
    }
    
    private func getNearbyStations(for location: CLLocation) -> [TideStation] {
        // Return some example stations near the location
        return [
            TideStation(id: "9414290", name: "San Francisco, CA", state: "CA", latitude: 37.8067, longitude: -122.4653),
            TideStation(id: "9410170", name: "San Diego, CA", state: "CA", latitude: 32.7142, longitude: -117.1734),
            TideStation(id: "8729108", name: "Panama City, FL", state: "FL", latitude: 30.1523, longitude: -85.6669)
        ]
    }
    
    private func getAllStations() -> [TideStation] {
        return [
            TideStation(id: "9414290", name: "San Francisco, CA", state: "CA", latitude: 37.8067, longitude: -122.4653),
            TideStation(id: "9410170", name: "San Diego, CA", state: "CA", latitude: 32.7142, longitude: -117.1734),
            TideStation(id: "8729108", name: "Panama City, FL", state: "FL", latitude: 30.1523, longitude: -85.6669),
            TideStation(id: "8518750", name: "The Battery, NY", state: "NY", latitude: 40.7006, longitude: -74.0141),
            TideStation(id: "9447130", name: "Seattle, WA", state: "WA", latitude: 47.6029, longitude: -122.3394),
            TideStation(id: "8721604", name: "Dauphin Island, AL", state: "AL", latitude: 30.2503, longitude: -88.0750),
            TideStation(id: "8665530", name: "Charleston, SC", state: "SC", latitude: 32.7817, longitude: -79.9253),
            TideStation(id: "8729840", name: "Pensacola, FL", state: "FL", latitude: 30.4041, longitude: -87.2119)
        ]
    }
}

// MARK: - Error Types
enum TideAPIError: Error, LocalizedError {
    case invalidURL
    case serverError
    case noData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .serverError:
            return "Server error occurred"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}
