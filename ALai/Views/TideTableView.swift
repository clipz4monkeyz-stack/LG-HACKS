//
//  TideTableView.swift
//  ALai
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct TideTableView: View {
    let tideData: TideGraphData
    
    var body: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Time")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 6) {
                    Image(systemName: "ruler")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Height")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .frame(width: 80, alignment: .trailing)
                
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Type")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                .frame(width: 70, alignment: .center)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color(.systemGray6).opacity(0.8), Color(.systemGray5).opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Table Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(tideData.points.enumerated()), id: \.element.time) { index, point in
                        TideTableRowView(
                            point: point,
                            isCurrentTime: isCurrentTime(point.time),
                            isAlternating: index % 2 == 1
                        )
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    private func isCurrentTime(_ time: Date) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        return calendar.isDate(time, equalTo: now, toGranularity: .hour)
    }
}

struct TideTableRowView: View {
    let point: TidePoint
    let isCurrentTime: Bool
    let isAlternating: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Time Column
            VStack(alignment: .leading, spacing: 2) {
                Text(formatTime(point.time))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(isCurrentTime ? .semibold : .regular)
                    .foregroundColor(isCurrentTime ? .primary : .primary)
                
                Text(formatDate(point.time))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Height Column
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f", point.height))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(isCurrentTime ? .accentColor : .primary)
                
                Text("m")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .trailing)
            
            // Type Column
            HStack(spacing: 4) {
                Image(systemName: point.type == .high ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(point.type == .high ? .blue : .orange)
                
                Text(point.type == .high ? "High" : "Low")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(point.type == .high ? .blue : .orange)
            }
            .frame(width: 70, alignment: .center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Group {
                if isCurrentTime {
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else if isAlternating {
                    Color(.systemGray6).opacity(0.3)
                } else {
                    Color.clear
                }
            }
        )
        .overlay(
            // Current time indicator
            isCurrentTime ? 
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.accentColor)
                .frame(width: 4)
                .frame(maxHeight: .infinity, alignment: .leading) : nil
        )
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
    TideTableView(tideData: TideGraphData(
        points: [
            TidePoint(time: Date(), height: 2.5, type: .high),
            TidePoint(time: Date().addingTimeInterval(3600), height: 1.8, type: .low),
            TidePoint(time: Date().addingTimeInterval(7200), height: 3.2, type: .high)
        ],
        currentHeight: 2.5,
        currentTime: Date()
    ))
    .padding()
}
