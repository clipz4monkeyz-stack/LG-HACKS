//
//  LanguagePickerView.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI

struct LanguagePickerView: View {
    @Binding var selectedLanguage: Language
    @Environment(\.dismiss) private var dismiss
    @StateObject private var translationService = LocalazyTranslationService()
    @State private var supportedLanguages: [Language] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading languages...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(supportedLanguages) { language in
                        LanguageRow(
                            language: language,
                            isSelected: selectedLanguage.code == language.code
                        ) {
                            selectedLanguage = language
                            dismiss()
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadSupportedLanguages()
            }
        }
    }
    
    private func loadSupportedLanguages() {
        Task {
            do {
                let languages = try await translationService.getSupportedLanguages()
                await MainActor.run {
                    supportedLanguages = languages
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    supportedLanguages = translationService.getMockSupportedLanguages()
                    isLoading = false
                }
            }
        }
    }
}

struct LanguageRow: View {
    let language: Language
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.nativeName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(language.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LanguagePickerView(selectedLanguage: .constant(Language(code: "en", name: "English", nativeName: "English")))
}
