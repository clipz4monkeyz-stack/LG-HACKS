//
//  ValidationResultView.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct ValidationResultView: View {
    let validationResult: ValidationResult?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let result = validationResult {
                        validationContent(result)
                    } else {
                        Text("No validation results available")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Validation Results")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func validationContent(_ result: ValidationResult) -> some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: result.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(result.isValid ? .green : .orange)
                
                Text(result.isValid ? "Form Valid" : "Issues Found")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(result.isValid ? "Your form looks good to submit!" : "Please review the issues below before submitting")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Errors
            if !result.errors.isEmpty {
                ValidationSection(
                    title: "Errors",
                    icon: "xmark.circle.fill",
                    color: .red,
                    items: result.errors.map { error in
                        ValidationItem(
                            text: "\(error.field): \(error.message)",
                            severity: error.severity
                        )
                    }
                )
            }
            
            // Warnings
            if !result.warnings.isEmpty {
                ValidationSection(
                    title: "Warnings",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange,
                    items: result.warnings.map { warning in
                        ValidationItem(text: warning, severity: .medium)
                    }
                )
            }
            
            // Suggestions
            if !result.suggestions.isEmpty {
                ValidationSection(
                    title: "Suggestions",
                    icon: "lightbulb.fill",
                    color: .blue,
                    items: result.suggestions.map { suggestion in
                        ValidationItem(text: suggestion, severity: .low)
                    }
                )
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                if result.isValid {
                    Button(action: {
                        // Submit form
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Submit Form")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    Button(action: {
                        // Fix errors
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Fix Issues")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Continue Editing")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct ValidationSection: View {
    let title: String
    let icon: String
    let color: Color
    let items: [ValidationItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(items.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                ValidationItemRow(item: item)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ValidationItemRow: View {
    let item: ValidationItem
    
    private var severityColor: Color {
        switch item.severity {
        case .critical:
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
        HStack(alignment: .top) {
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            Text(item.text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct ValidationItem {
    let text: String
    let severity: ErrorSeverity
}

#Preview {
    ValidationResultView(validationResult: ValidationResult(
        isValid: false,
        errors: [
            ValidationError(field: "Date of Birth", message: "Invalid date format", severity: .high),
            ValidationError(field: "Phone Number", message: "Missing area code", severity: .medium)
        ],
        warnings: [
            "Consider having a lawyer review before submission",
            "Double-check all dates for accuracy"
        ],
        suggestions: [
            "Include additional supporting documents",
            "Consider expedited processing if eligible"
        ]
    ))
}
