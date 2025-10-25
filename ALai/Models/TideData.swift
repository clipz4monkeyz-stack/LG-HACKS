//
//  TideData.swift
//  ALai
//
//  Created by Anwen Li on 9/24/25.
//

import Foundation

// MARK: - NOAA API Response Models
struct TideStation: Codable, Identifiable {
    let id: String
    let name: String
    let state: String?
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case state = "state"
        case latitude = "lat"
        case longitude = "lng"
    }
}

struct TidePrediction: Codable {
    let time: String
    let height: Double
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case time = "t"
        case height = "v"
        case type = "type"
    }
}

struct TideDataResponse: Codable {
    let predictions: [TidePrediction]
    
    enum CodingKeys: String, CodingKey {
        case predictions = "predictions"
    }
}

// MARK: - App Data Models
struct TidePoint: Identifiable {
    let id = UUID()
    let time: Date
    let height: Double
    let type: TideType
}

enum TideType: String, CaseIterable {
    case high = "H"
    case low = "L"
    
    var displayName: String {
        switch self {
        case .high: return "High Tide"
        case .low: return "Low Tide"
        }
    }
}

struct UserLocation: Codable, Equatable {
    let stationId: String
    let stationName: String
    let latitude: Double
    let longitude: Double
    let state: String?
}

// MARK: - Tide Graph Data
struct TideGraphData {
    let points: [TidePoint]
    let currentHeight: Double
    let currentTime: Date
    
    var minHeight: Double {
        points.map(\.height).min() ?? 0
    }
    
    var maxHeight: Double {
        points.map(\.height).max() ?? 0
    }
    
    var zoomedPoints: [TidePoint] {
        // For table view, return all 24 hours of data
        return points
    }
    
    var highTides: [TidePoint] {
        return points.filter { $0.type == .high }.sorted { $0.time < $1.time }
    }
    
    var lowTides: [TidePoint] {
        return points.filter { $0.type == .low }.sorted { $0.time < $1.time }
    }
}
