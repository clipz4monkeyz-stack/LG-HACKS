// LLM Integration JavaScript Module
// Handles communication with the Immigration LLM API

class ImmigrationLLMService {
    constructor(apiBaseUrl = 'http://localhost:8000') {
        this.apiBaseUrl = apiBaseUrl;
        this.currentDocumentId = null;
        this.analysisCache = new Map();
    }

    // Document Upload and Processing
    async uploadDocument(file) {
        try {
            const formData = new FormData();
            formData.append('file', file);

            const response = await fetch(`${this.apiBaseUrl}/upload-pdf`, {
                method: 'POST',
                body: formData
            });

            if (!response.ok) {
                throw new Error(`Upload failed: ${response.statusText}`);
            }

            const result = await response.json();
            this.currentDocumentId = result.document_id;
            
            return {
                success: true,
                documentId: result.document_id,
                documentType: result.document_type,
                pageCount: result.page_count,
                confidence: result.confidence_score,
                message: result.message
            };
        } catch (error) {
            console.error('Document upload error:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    // Document Analysis
    async analyzeDocument(documentId, analysisType = 'comprehensive', questions = []) {
        try {
            const response = await fetch(`${this.apiBaseUrl}/analyze-document`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    document_id: documentId,
                    analysis_type: analysisType,
                    questions: questions
                })
            });

            if (!response.ok) {
                throw new Error(`Analysis failed: ${response.statusText}`);
            }

            const result = await response.json();
            
            // Cache the analysis
            this.analysisCache.set(documentId, result.analysis);
            
            return {
                success: true,
                analysisId: result.analysis_id,
                analysis: result.analysis,
                documentId: result.document_id
            };
        } catch (error) {
            console.error('Document analysis error:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    // Ask Questions
    async askQuestion(documentId, question) {
        try {
            const response = await fetch(`${this.apiBaseUrl}/ask-question`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    document_id: documentId,
                    question: question
                })
            });

            if (!response.ok) {
                throw new Error(`Question failed: ${response.statusText}`);
            }

            const result = await response.json();
            
            return {
                success: true,
                answer: result.answer,
                confidence: result.confidence,
                source: result.source
            };
        } catch (error) {
            console.error('Question error:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    // Document Translation
    async translateDocument(documentId, targetLanguage) {
        try {
            const response = await fetch(`${this.apiBaseUrl}/translate-document`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    document_id: documentId,
                    target_language: targetLanguage
                })
            });

            if (!response.ok) {
                throw new Error(`Translation failed: ${response.statusText}`);
            }

            const result = await response.json();
            
            return {
                success: true,
                translatedContent: result.translated_content,
                targetLanguage: result.target_language,
                confidence: result.confidence
            };
        } catch (error) {
            console.error('Translation error:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    // Document Simplification
    async simplifyDocument(documentId) {
        try {
            const response = await fetch(`${this.apiBaseUrl}/simplify-document`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    document_id: documentId
                })
            });

            if (!response.ok) {
                throw new Error(`Simplification failed: ${response.statusText}`);
            }

            const result = await response.json();
            
            return {
                success: true,
                simplifiedContent: result.simplified_content,
                confidence: result.confidence
            };
        } catch (error) {
            console.error('Simplification error:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    // Get Document Status
    async getDocumentStatus(documentId) {
        try {
            const response = await fetch(`${this.apiBaseUrl}/document-status/${documentId}`);
            
            if (!response.ok) {
                throw new Error(`Status check failed: ${response.statusText}`);
            }

            const result = await response.json();
            
            return {
                success: true,
                status: result
            };
        } catch (error) {
            console.error('Status check error:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    // List All Documents
    async listDocuments() {
        try {
            const response = await fetch(`${this.apiBaseUrl}/documents`);
            
            if (!response.ok) {
                throw new Error(`List documents failed: ${response.statusText}`);
            }

            const result = await response.json();
            
            return {
                success: true,
                documents: result.documents
            };
        } catch (error) {
            console.error('List documents error:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    // Health Check
    async healthCheck() {
        try {
            const response = await fetch(`${this.apiBaseUrl}/health`);
            
            if (!response.ok) {
                throw new Error(`Health check failed: ${response.statusText}`);
            }

            const result = await response.json();
            
            return {
                success: true,
                health: result
            };
        } catch (error) {
            console.error('Health check error:', error);
            return {
                success: false,
                error: error.message
            };
        }
    }

    // Utility Methods
    formatAnalysisResult(analysis) {
        if (!analysis) return null;

        return {
            summary: analysis.summary || 'No summary available',
            keyInformation: analysis.key_information || {},
            formFieldsAnalysis: analysis.form_fields_analysis || [],
            recommendations: analysis.recommendations || [],
            questionsAnswered: analysis.questions_answered || {},
            confidenceScore: analysis.confidence_score || 0
        };
    }

    generateQuestionsForDocument(documentType) {
        const questionTemplates = {
            'I-130': [
                'What is the deadline for submitting this petition?',
                'What supporting documents are required?',
                'What are the eligibility requirements?',
                'How much does it cost to file this form?'
            ],
            'I-485': [
                'What is the processing time for this application?',
                'What documents do I need to submit?',
                'What are the eligibility requirements?',
                'Can I work while this application is pending?'
            ],
            'I-765': [
                'How long is the employment authorization valid?',
                'What documents are required for renewal?',
                'Can I travel outside the US with this document?',
                'What is the processing fee?'
            ],
            'I-821D': [
                'What are the DACA eligibility requirements?',
                'How often do I need to renew?',
                'What documents prove continuous residence?',
                'What happens if my DACA expires?'
            ],
            'default': [
                'What is the purpose of this document?',
                'What are the key requirements?',
                'What supporting documents are needed?',
                'What are the important deadlines?',
                'What are the fees involved?'
            ]
        };

        return questionTemplates[documentType] || questionTemplates['default'];
    }

    // Error Handling
    handleError(error, context = '') {
        console.error(`LLM Service Error ${context}:`, error);
        
        const errorMessages = {
            'network': 'Network error. Please check your connection.',
            'server': 'Server error. Please try again later.',
            'validation': 'Invalid input. Please check your data.',
            'auth': 'Authentication error. Please check your API keys.',
            'rate_limit': 'Rate limit exceeded. Please wait before trying again.'
        };

        return errorMessages[error.type] || 'An unexpected error occurred.';
    }
}

// Enhanced Chat Interface
class AIChatInterface {
    constructor(llmService) {
        this.llmService = llmService;
        this.chatHistory = [];
        this.isProcessing = false;
    }

    async sendMessage(message, documentId = null) {
        if (this.isProcessing) return;

        this.isProcessing = true;
        
        // Add user message to history
        this.chatHistory.push({
            type: 'user',
            message: message,
            timestamp: new Date()
        });

        try {
            let response;
            
            if (documentId) {
                // Ask question about specific document
                const result = await this.llmService.askQuestion(documentId, message);
                
                if (result.success) {
                    response = {
                        type: 'ai',
                        message: result.answer,
                        confidence: result.confidence,
                        source: result.source,
                        timestamp: new Date()
                    };
                } else {
                    response = {
                        type: 'ai',
                        message: `I'm sorry, I couldn't process your question: ${result.error}`,
                        confidence: 0,
                        timestamp: new Date()
                    };
                }
            } else {
                // General immigration assistance
                response = {
                    type: 'ai',
                    message: this.generateGeneralResponse(message),
                    confidence: 0.8,
                    timestamp: new Date()
                };
            }

            this.chatHistory.push(response);
            return response;

        } catch (error) {
            const errorResponse = {
                type: 'ai',
                message: 'I apologize, but I encountered an error processing your request.',
                confidence: 0,
                timestamp: new Date()
            };
            
            this.chatHistory.push(errorResponse);
            return errorResponse;
        } finally {
            this.isProcessing = false;
        }
    }

    generateGeneralResponse(message) {
        const responses = {
            'daca': 'DACA (Deferred Action for Childhood Arrivals) provides temporary protection from deportation and work authorization for eligible individuals who came to the US as children. Would you like me to help you with DACA-related questions?',
            'green card': 'A green card (permanent resident card) allows you to live and work permanently in the United States. There are several ways to obtain a green card, including through family, employment, or special programs.',
            'citizenship': 'US citizenship can be obtained through naturalization if you meet certain requirements, including being a permanent resident for a specific period and demonstrating good moral character.',
            'work permit': 'A work permit (Employment Authorization Document) allows you to work legally in the United States. The requirements and validity period depend on your immigration status.',
            'visa': 'US visas allow foreign nationals to enter the United States for specific purposes. There are many types of visas, including tourist, student, work, and family visas.'
        };

        const messageLower = message.toLowerCase();
        
        for (const [keyword, response] of Object.entries(responses)) {
            if (messageLower.includes(keyword)) {
                return response;
            }
        }

        return 'I\'m here to help with immigration-related questions. You can ask me about forms, requirements, deadlines, or upload documents for analysis. How can I assist you today?';
    }

    getChatHistory() {
        return this.chatHistory;
    }

    clearChatHistory() {
        this.chatHistory = [];
    }
}

// Document Analysis Display
class DocumentAnalysisDisplay {
    constructor(containerId) {
        this.container = document.getElementById(containerId);
        this.llmService = new ImmigrationLLMService();
    }

    async displayAnalysis(documentId) {
        try {
            const result = await this.llmService.analyzeDocument(documentId);
            
            if (!result.success) {
                this.showError(result.error);
                return;
            }

            const analysis = this.llmService.formatAnalysisResult(result.analysis);
            this.renderAnalysis(analysis);

        } catch (error) {
            this.showError('Failed to load document analysis');
        }
    }

    renderAnalysis(analysis) {
        if (!analysis) return;

        this.container.innerHTML = `
            <div class="analysis-container">
                <div class="analysis-section">
                    <h3>📋 Document Summary</h3>
                    <p>${analysis.summary}</p>
                </div>

                <div class="analysis-section">
                    <h3>🔑 Key Information</h3>
                    <div class="key-info-grid">
                        ${this.renderKeyInformation(analysis.keyInformation)}
                    </div>
                </div>

                <div class="analysis-section">
                    <h3>📝 Form Field Analysis</h3>
                    <div class="form-fields">
                        ${this.renderFormFields(analysis.formFieldsAnalysis)}
                    </div>
                </div>

                <div class="analysis-section">
                    <h3>💡 Recommendations</h3>
                    <ul class="recommendations">
                        ${analysis.recommendations.map(rec => `<li>${rec}</li>`).join('')}
                    </ul>
                </div>

                <div class="analysis-section">
                    <h3>❓ Questions & Answers</h3>
                    <div class="qa-section">
                        ${this.renderQuestionsAnswered(analysis.questionsAnswered)}
                    </div>
                </div>

                <div class="confidence-score">
                    <span>Confidence Score: ${(analysis.confidenceScore * 100).toFixed(1)}%</span>
                </div>
            </div>
        `;
    }

    renderKeyInformation(keyInfo) {
        if (!keyInfo || Object.keys(keyInfo).length === 0) {
            return '<p>No key information extracted</p>';
        }

        return Object.entries(keyInfo).map(([key, value]) => `
            <div class="key-info-item">
                <strong>${key.replace(/_/g, ' ').toUpperCase()}:</strong>
                <span>${Array.isArray(value) ? value.join(', ') : value}</span>
            </div>
        `).join('');
    }

    renderFormFields(formFields) {
        if (!formFields || formFields.length === 0) {
            return '<p>No form fields found</p>';
        }

        return formFields.map(field => `
            <div class="form-field-item">
                <h4>${field.field_name}</h4>
                <p><strong>Type:</strong> ${field.field_type}</p>
                <p><strong>Guidance:</strong> ${field.guidance}</p>
                <p><strong>Page:</strong> ${field.page_number}</p>
            </div>
        `).join('');
    }

    renderQuestionsAnswered(questionsAnswered) {
        if (!questionsAnswered || Object.keys(questionsAnswered).length === 0) {
            return '<p>No questions answered</p>';
        }

        return Object.entries(questionsAnswered).map(([question, answer]) => `
            <div class="qa-item">
                <h4>Q: ${question}</h4>
                <p>A: ${answer}</p>
            </div>
        `).join('');
    }

    showError(message) {
        this.container.innerHTML = `
            <div class="error-message">
                <h3>❌ Error</h3>
                <p>${message}</p>
            </div>
        `;
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        ImmigrationLLMService,
        AIChatInterface,
        DocumentAnalysisDisplay
    };
}

