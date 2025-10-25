//
//  ChatbotView.swift
//  NavigateHome AI
//
//  Created by Anwen Li on 9/24/25.
//

import SwiftUI
import PhotosUI

struct ChatbotView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var aiService: NavigateHomeAIService
    @StateObject private var translationService = LocalazyTranslationService()
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isRecording = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var isLoading = false
    @State private var selectedLanguage: Language = Language(code: "en", name: "English", nativeName: "English")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }
                            
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("AI is thinking...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .id("loading")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation {
                            if let lastMessage = messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            } else {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Section
                VStack(spacing: 12) {
                    // Language Selector
                    HStack {
                        Text("Language:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            // Show language picker
                        }) {
                            HStack {
                                Text(selectedLanguage.nativeName)
                                    .font(.caption)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        }
                        
                        Spacer()
                    }
                    
                    // Input Area
                    HStack(spacing: 12) {
                        // PDF Attachment Button
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image(systemName: "paperclip")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                        
                        // Text Input
                        TextField("Ask me anything about your immigration case...", text: $messageText, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(20)
                            .lineLimit(1...4)
                        
                        // Speech to Text Button
                        Button(action: {
                            toggleRecording()
                        }) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                                .foregroundColor(isRecording ? .red : .blue)
                                .font(.title2)
                        }
                        
                        // Send Button
                        Button(action: {
                            sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(messageText.isEmpty ? .gray : .blue)
                                .font(.title2)
                        }
                        .disabled(messageText.isEmpty)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                addWelcomeMessage()
            }
            .onChange(of: selectedItem) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        // Process uploaded image/document
                        await processUploadedDocument(data)
                    }
                }
            }
        }
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            content: "Hello! I'm your AI immigration assistant. I can help you understand your case status, find required documents, answer questions about immigration processes, and connect you with resources. How can I help you today?",
            isFromUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(
            content: messageText,
            isFromUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        let messageToProcess = messageText
        messageText = ""
        
        Task {
            await processMessage(messageToProcess)
        }
    }
    
    private func processMessage(_ message: String) async {
        isLoading = true
        
        // Translate message to English if needed
        let processedMessage = selectedLanguage.code != "en" ? 
            (try? await translationService.translateText(message, from: selectedLanguage.code, to: "en")) ?? message :
            message
        
        // Get AI response
        let response = await getAIResponse(for: processedMessage)
        
        // Translate response back to user's language if needed
        let finalResponse = selectedLanguage.code != "en" ? 
            (try? await translationService.translateText(response, from: "en", to: selectedLanguage.code)) ?? response :
            response
        
        await MainActor.run {
            let aiMessage = ChatMessage(
                content: finalResponse,
                isFromUser: false,
                timestamp: Date()
            )
            messages.append(aiMessage)
            isLoading = false
        }
    }
    
    private func getAIResponse(for message: String) async -> String {
        // This would integrate with your AI service to get contextual responses
        // For now, return mock responses based on common questions
        
        let lowercasedMessage = message.lowercased()
        
        if lowercasedMessage.contains("status") || lowercasedMessage.contains("case") {
            return "Based on your profile, I can see you have a DACA case in progress. Your current status is 'In Review' and you should expect a response within 4-6 months. Would you like me to help you check what documents you still need to submit?"
        } else if lowercasedMessage.contains("document") || lowercasedMessage.contains("paperwork") {
            return "I can help you identify the documents you need for your case. For DACA renewal, you typically need: 1) Current DACA card, 2) Passport or birth certificate, 3) Proof of continuous residence, 4) Passport photos. Would you like me to create a personalized checklist for you?"
        } else if lowercasedMessage.contains("help") || lowercasedMessage.contains("assistance") {
            return "I'm here to help! I can assist you with: 1) Understanding your case status, 2) Finding required documents, 3) Locating free legal help, 4) Connecting you with community resources, 5) Translating forms and documents. What specific help do you need?"
        } else if lowercasedMessage.contains("legal") || lowercasedMessage.contains("lawyer") {
            return "I can help you find free legal assistance! Based on your location, I recommend: 1) Legal Aid Society (free consultations), 2) Immigrant Legal Resource Center, 3) Local law school clinics. Would you like me to provide contact information and help you schedule an appointment?"
        } else {
            return "I understand you're asking about '\(message)'. I'm here to help with your immigration case. I can assist with case status, required documents, finding legal help, and connecting you with resources. Could you be more specific about what you need help with?"
        }
    }
    
    private func processUploadedDocument(_ data: Data) async {
        // Process uploaded document
        let documentMessage = ChatMessage(
            content: "I've received your document. Let me analyze it and provide guidance on what you need to do next.",
            isFromUser: false,
            timestamp: Date()
        )
        
        await MainActor.run {
            messages.append(documentMessage)
        }
        
        // Here you would integrate with document analysis service
        // For now, provide a mock response
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
        
        let analysisMessage = ChatMessage(
            content: "I've analyzed your document. This appears to be a USCIS form. I can help you understand what information is needed and guide you through completing it correctly. Would you like me to explain any specific sections?",
            isFromUser: false,
            timestamp: Date()
        )
        
        await MainActor.run {
            messages.append(analysisMessage)
        }
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        
        if isRecording {
            // Start speech recognition
            // This would integrate with Speech framework
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isRecording = false
                messageText = "I need help with my immigration case" // Mock speech-to-text result
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity * 0.8, alignment: .trailing)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(20)
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity * 0.8, alignment: .leading)
                
                Spacer()
            }
        }
    }
}

#Preview {
    ChatbotView()
        .environmentObject(UserManager())
        .environmentObject(NavigateHomeAIService())
}
