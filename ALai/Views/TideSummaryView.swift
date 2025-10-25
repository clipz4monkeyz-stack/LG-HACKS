//
//  TideSummaryView.swift
//  ALai
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct TideSummaryView: View {
    let tideData: TideGraphData
    
    var body: some View {
        VStack(spacing: 16) {
            // High Tides Section
            TideSummarySection(
                title: "High Tides",
                icon: "arrow.up.circle.fill",
                iconColor: .blue,
                tides: tideData.highTides
            )
            
            // Low Tides Section
            TideSummarySection(
                title: "Low Tides",
                icon: "arrow.down.circle.fill",
                iconColor: .orange,
                tides: tideData.lowTides
            )
        }
    }
}

struct TideSummarySection: View {
    let title: String
    let icon: String
    let iconColor: Color
    let tides: [TidePoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(iconColor)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Text("\(tides.count) tides")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray5))
                    )
            }
            
            // Tide Items
            if tides.isEmpty {
                Text("No \(title.lowercased()) data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(tides, id: \.time) { tide in
                        TideSummaryItem(tide: tide)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}

struct TideSummaryItem: View {
    let tide: TidePoint
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatTime(tide.time))
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(formatDate(tide.time))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", tide.height))
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("meters")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

#Preview {
    TideSummaryView(tideData: TideGraphData(
        points: [
            TidePoint(time: Date(), height: 2.5, type: .high),
            TidePoint(time: Date().addingTimeInterval(3600), height: 1.8, type: .low),
            TidePoint(time: Date().addingTimeInterval(7200), height: 3.2, type: .high),
            TidePoint(time: Date().addingTimeInterval(10800), height: 0.9, type: .low)
        ],
        currentHeight: 2.5,
        currentTime: Date()
    ))
    .padding()
}
