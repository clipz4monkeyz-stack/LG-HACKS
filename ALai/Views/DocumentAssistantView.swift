//
//  DocumentAssistantView.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI
import PhotosUI

struct DocumentAssistantView: View {
    @EnvironmentObject var aiService: NavigateHomeAIService
    @EnvironmentObject var userManager: UserManager
    @State private var selectedForm: ImmigrationForm?
    @State private var showingFormPicker = false
    @State private var showingDocumentUpload = false
    @State private var uploadedDocument: Data?
    @State private var formAnalysis: FormAnalysisResult?
    @State private var currentStep = 0
    @State private var userAnswers: [String: String] = [:]
    @State private var showingValidation = false
    @State private var validationResult: ValidationResult?
    
    private let commonForms = [
        ImmigrationForm(formNumber: "I-485", title: "Application to Register Permanent Residence or Adjust Status", description: "Apply for a green card", category: .adjustmentOfStatus),
        ImmigrationForm(formNumber: "I-130", title: "Petition for Alien Relative", description: "Petition for family member", category: .familyPetition),
        ImmigrationForm(formNumber: "N-400", title: "Application for Naturalization", description: "Apply for US citizenship", category: .naturalization),
        ImmigrationForm(formNumber: "I-765", title: "Application for Employment Authorization", description: "Apply for work permit", category: .workAuthorization),
        ImmigrationForm(formNumber: "I-131", title: "Application for Travel Document", description: "Apply for travel permit", category: .travelDocument),
        ImmigrationForm(formNumber: "I-90", title: "Application to Replace Permanent Resident Card", description: "Replace green card", category: .renewal)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let analysis = formAnalysis {
                        formAnalysisView(analysis)
                    } else if let form = selectedForm {
                        formSelectionView(form)
                    } else {
                        formPickerView
                    }
                }
                .padding()
            }
            .navigationTitle("Document Assistant")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFormPicker) {
                FormPickerView(forms: commonForms) { form in
                    selectedForm = form
                    showingFormPicker = false
                }
            }
            .sheet(isPresented: $showingDocumentUpload) {
                DocumentUploadView { documentData in
                    uploadedDocument = documentData
                    showingDocumentUpload = false
                    analyzeDocument()
                }
            }
            .sheet(isPresented: $showingValidation) {
                ValidationResultView(validationResult: validationResult)
            }
        }
    }
    
    private var formPickerView: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Intelligent Document Assistant")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Get step-by-step guidance for immigration forms in your native language")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Action Buttons
            VStack(spacing: 16) {
                Button(action: {
                    showingFormPicker = true
                }) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("Choose a Form")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    showingDocumentUpload = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Upload Document")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            // Recent Forms
            if let user = userManager.currentUser, !user.caseHistory.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Forms")
                        .font(.headline)
                    
                    ForEach(user.caseHistory.prefix(3)) { caseRecord in
                        if caseRecord.caseType == .immigration {
                            RecentFormCard(caseRecord: caseRecord)
                        }
                    }
                }
            }
        }
    }
    
    private func formSelectionView(_ form: ImmigrationForm) -> some View {
        VStack(spacing: 20) {
            // Form Header
            VStack(spacing: 12) {
                Text(form.formNumber)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Text(form.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(form.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Form Details
            VStack(spacing: 16) {
                FormDetailRow(title: "Difficulty", value: form.difficulty.rawValue, color: difficultyColor(form.difficulty))
                FormDetailRow(title: "Estimated Time", value: "\(form.estimatedTime) minutes", color: .blue)
                FormDetailRow(title: "Filing Fee", value: form.filingFee != nil ? "$\(Int(form.filingFee!))" : "Varies", color: .green)
            }
            
            // Required Documents
            if !form.requiredDocuments.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Required Documents")
                        .font(.headline)
                    
                    ForEach(form.requiredDocuments, id: \.self) { docType in
                        DocumentRequirementCard(documentType: docType)
                    }
                }
            }
            
            // Common Mistakes
            if !form.commonMistakes.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Common Mistakes to Avoid")
                        .font(.headline)
                    
                    ForEach(form.commonMistakes, id: \.self) { mistake in
                        MistakeCard(mistake: mistake)
                    }
                }
            }
            
            // Tips
            if !form.tips.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Helpful Tips")
                        .font(.headline)
                    
                    ForEach(form.tips, id: \.self) { tip in
                        TipCard(tip: tip)
                    }
                }
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    startFormFilling(form)
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Start Filling Form")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    selectedForm = nil
                }) {
                    Text("Choose Different Form")
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func formAnalysisView(_ analysis: FormAnalysisResult) -> some View {
        VStack(spacing: 20) {
            // Analysis Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                
                Text("Document Analysis Complete")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Form Type: \(analysis.formType)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Analysis Results
            VStack(spacing: 16) {
                AnalysisResultCard(
                    title: "Difficulty Level",
                    value: analysis.difficulty.rawValue,
                    color: difficultyColor(analysis.difficulty)
                )
                
                AnalysisResultCard(
                    title: "Estimated Time",
                    value: "\(analysis.estimatedTime) minutes",
                    color: .blue
                )
                
                AnalysisResultCard(
                    title: "Required Documents",
                    value: "\(analysis.requiredDocuments.count) documents",
                    color: .orange
                )
            }
            
            // Warnings
            if !analysis.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Important Warnings")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    ForEach(analysis.warnings, id: \.self) { warning in
                        WarningCard(warning: warning)
                    }
                }
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    startFormFillingFromAnalysis(analysis)
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Guided Filling")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: {
                    formAnalysis = nil
                    uploadedDocument = nil
                }) {
                    Text("Analyze Different Document")
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func difficultyColor(_ difficulty: DifficultyLevel) -> Color {
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
    
    private func startFormFilling(_ form: ImmigrationForm) {
        // Create a case record for this form
        let caseRecord = CaseRecord(caseType: .immigration, description: "\(form.formNumber) - \(form.title)")
        userManager.addCase(caseRecord)
        
        // Navigate to form filling (in a real app, this would navigate to a form filling view)
        // For now, we'll show a placeholder
    }
    
    private func startFormFillingFromAnalysis(_ analysis: FormAnalysisResult) {
        // Create a case record for this form
        let caseRecord = CaseRecord(caseType: .immigration, description: "\(analysis.formType) Application")
        userManager.addCase(caseRecord)
        
        // Navigate to form filling
    }
    
    private func analyzeDocument() {
        guard let documentData = uploadedDocument else { return }
        
        Task {
            let analysis = await aiService.analyzeImmigrationForm(documentData, formType: "Unknown")
            await MainActor.run {
                formAnalysis = analysis
            }
        }
    }
}

struct FormDetailRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct DocumentRequirementCard: View {
    let documentType: DocumentType
    
    var body: some View {
        HStack {
            Image(systemName: "doc.fill")
                .foregroundColor(.blue)
            
            Text(documentType.rawValue)
                .font(.subheadline)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct MistakeCard: View {
    let mistake: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(mistake)
                .font(.subheadline)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TipCard: View {
    let tip: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            
            Text(tip)
                .font(.subheadline)
            
            Spacer()
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AnalysisResultCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct WarningCard: View {
    let warning: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(warning)
                .font(.subheadline)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

struct RecentFormCard: View {
    let caseRecord: CaseRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(caseRecord.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Status: \(caseRecord.status.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    DocumentAssistantView()
        .environmentObject(NavigateHomeAIService())
        .environmentObject(UserManager())
}
