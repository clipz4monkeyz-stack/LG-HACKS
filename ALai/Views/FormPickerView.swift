//
//  FormPickerView.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct FormPickerView: View {
    let forms: [ImmigrationForm]
    let onFormSelected: (ImmigrationForm) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredForms: [ImmigrationForm] {
        if searchText.isEmpty {
            return forms
        } else {
            return forms.filter { form in
                form.title.localizedCaseInsensitiveContains(searchText) ||
                form.formNumber.localizedCaseInsensitiveContains(searchText) ||
                form.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding()
                
                // Forms List
                List(filteredForms) { form in
                    FormPickerRow(form: form) {
                        onFormSelected(form)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Choose a Form")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FormPickerRow: View {
    let form: ImmigrationForm
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(form.formNumber)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    DifficultyBadge(difficulty: form.difficulty)
                }
                
                Text(form.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(form.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Label("\(form.estimatedTime) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let fee = form.filingFee {
                        Label("$\(Int(fee))", systemImage: "dollarsign.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DifficultyBadge: View {
    let difficulty: DifficultyLevel
    
    private var color: Color {
        switch difficulty {
        case .easy:
            return .green
        case .medium:
            return .yellow
        case .hard:
            return .orange
        case .expert:
            return .red
        }
    }
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search forms...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

#Preview {
    FormPickerView(forms: [
        ImmigrationForm(formNumber: "I-485", title: "Application to Register Permanent Residence or Adjust Status", description: "Apply for a green card", category: .adjustmentOfStatus),
        ImmigrationForm(formNumber: "N-400", title: "Application for Naturalization", description: "Apply for US citizenship", category: .naturalization)
    ]) { _ in }
}
