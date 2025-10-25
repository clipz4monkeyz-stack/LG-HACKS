//
//  TideGraphView.swift
//  ALai
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct TideGraphView: View {
    let tideData: TideGraphData
    let height: CGFloat = 200
    
    private var zoomedPoints: [TidePoint] {
        tideData.zoomedPoints
    }
    
    private var currentPoint: TidePoint? {
        zoomedPoints.first { point in
            abs(point.time.timeIntervalSince(tideData.currentTime)) < 30 * 60
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with current tide info
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Tide")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(tideData.currentHeight, specifier: "%.1f") ft")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Next")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let nextTide = getNextTide() {
                        Text(nextTide.type.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(formatTime(nextTide.time))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            // Graph with axes, labels, and tide line
            VStack(spacing: 0) {
                // Y-axis labels (height)
                HStack(spacing: 0) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Height (ft)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(-90))
                            .frame(height: height / 5)
                        
                        ForEach(0..<5) { i in
                            let height = tideData.maxHeight - CGFloat(i) * (tideData.maxHeight - tideData.minHeight) / 4
                            Text("\(height, specifier: "%.1f")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(height: height / 5)
                        }
                    }
                    .frame(width: 50)
                    
                    // Graph with axes and tide line
                    GeometryReader { geometry in
                        ZStack {
                            // X-axis and Y-axis
                            axes(in: geometry.size)
                            
                            // Tide curve
                            tideCurve(in: geometry.size)
                        }
                    }
                    .frame(height: height)
                }
                
                // X-axis labels (time)
                VStack(spacing: 2) {
                    HStack {
                        Spacer()
                            .frame(width: 50)
                        
                        HStack {
                            ForEach(0..<7) { i in
                                if i < zoomedPoints.count {
                                    let point = zoomedPoints[i * max(1, (zoomedPoints.count - 1) / 6)]
                                    Text(formatTime(point.time))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    
                    // Time label
                    HStack {
                        Spacer()
                            .frame(width: 50)
                        
                        Text("Time")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.top, 4)
            }
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Graph Components
    
    private func axes(in size: CGSize) -> some View {
        let padding: CGFloat = 20
        
        return ZStack {
            // X-axis (horizontal line at bottom)
            Path { path in
                path.move(to: CGPoint(x: padding, y: size.height - padding))
                path.addLine(to: CGPoint(x: size.width - padding, y: size.height - padding))
            }
            .stroke(Color.primary, lineWidth: 1)
            
            // Y-axis (vertical line on left)
            Path { path in
                path.move(to: CGPoint(x: padding, y: padding))
                path.addLine(to: CGPoint(x: padding, y: size.height - padding))
            }
            .stroke(Color.primary, lineWidth: 1)
        }
    }
    
    private func backgroundGrid(in size: CGSize) -> some View {
        let stepX = size.width / 6
        let stepY = size.height / 4
        
        return ZStack {
            // Horizontal grid lines
            ForEach(0..<5) { i in
                Path { path in
                    let y = CGFloat(i) * stepY
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                }
                .stroke(Color(.separator), lineWidth: 0.5)
            }
            
            // Vertical grid lines
            ForEach(0..<7) { i in
                Path { path in
                    let x = CGFloat(i) * stepX
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                }
                .stroke(Color(.separator), lineWidth: 0.5)
            }
        }
    }
    
    private func tideCurve(in size: CGSize) -> some View {
        Path { path in
            guard !zoomedPoints.isEmpty else { return }
            
            let minHeight = tideData.minHeight
            let maxHeight = tideData.maxHeight
            let heightRange = maxHeight - minHeight
            let padding: CGFloat = 20
            
            let points = zoomedPoints.enumerated().map { index, point in
                let x = CGFloat(index) * (size.width - 2 * padding) / CGFloat(zoomedPoints.count - 1) + padding
                let normalizedHeight = heightRange > 0 ? (point.height - minHeight) / heightRange : 0.5
                let y = size.height - padding - normalizedHeight * (size.height - 2 * padding)
                return CGPoint(x: x, y: y)
            }
            
            guard let firstPoint = points.first else { return }
            path.move(to: firstPoint)
            
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(
            LinearGradient(
                colors: [.blue.opacity(0.8), .blue.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
    }
    
    private func currentTideIndicator(in size: CGSize) -> some View {
        Group {
            if let currentPoint = currentPoint,
               let currentIndex = zoomedPoints.firstIndex(where: { $0.id == currentPoint.id }) {
                
                let minHeight = tideData.minHeight
                let maxHeight = tideData.maxHeight
                let heightRange = maxHeight - minHeight
                let padding: CGFloat = 20
                
                let x = CGFloat(currentIndex) * (size.width - 2 * padding) / CGFloat(zoomedPoints.count - 1) + padding
                let normalizedHeight = heightRange > 0 ? (currentPoint.height - minHeight) / heightRange : 0.5
                let y = size.height - padding - normalizedHeight * (size.height - 2 * padding)
                
                Circle()
                    .fill(Color.orange)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .position(x: x, y: y)
                    .shadow(color: .orange.opacity(0.5), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private func tideMarkers(in size: CGSize) -> some View {
        ForEach(Array(zoomedPoints.enumerated()), id: \.element.id) { index, point in
            if point.type == .high || point.type == .low {
                let minHeight = tideData.minHeight
                let maxHeight = tideData.maxHeight
                let heightRange = maxHeight - minHeight
                let padding: CGFloat = 20
                
                let x = CGFloat(index) * (size.width - 2 * padding) / CGFloat(zoomedPoints.count - 1) + padding
                let normalizedHeight = heightRange > 0 ? (point.height - minHeight) / heightRange : 0.5
                let y = size.height - padding - normalizedHeight * (size.height - 2 * padding)
                
                VStack(spacing: 2) {
                    Image(systemName: point.type == .high ? "arrow.up" : "arrow.down")
                        .font(.caption)
                        .foregroundColor(point.type == .high ? .red : .blue)
                    
                    Text(formatTime(point.time))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .position(x: x, y: y - 25)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getNextTide() -> TidePoint? {
        return tideData.points.first { point in
            point.time > tideData.currentTime && (point.type == .high || point.type == .low)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    TideGraphView(tideData: TideGraphData(
        points: [
            TidePoint(time: Date().addingTimeInterval(-3600), height: 2.1, type: .low),
            TidePoint(time: Date().addingTimeInterval(-1800), height: 3.5, type: .high),
            TidePoint(time: Date(), height: 2.8, type: .low),
            TidePoint(time: Date().addingTimeInterval(1800), height: 4.2, type: .high),
            TidePoint(time: Date().addingTimeInterval(3600), height: 3.1, type: .low)
        ],
        currentHeight: 2.8,
        currentTime: Date()
    ))
    .padding()
}
