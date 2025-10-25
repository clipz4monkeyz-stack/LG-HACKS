#!/usr/bin/env python3
"""
Simple API server for Immigration LLM Integration Demo
Works without external API keys using mock responses
"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import asyncio
import os
import uuid
import json
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Immigration LLM API Demo",
    description="AI-powered immigration document processing and analysis (Demo Mode)",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mock data storage
document_cache = {}
analysis_cache = {}

# Pydantic models
class DocumentUploadResponse(BaseModel):
    document_id: str
    status: str
    message: str
    document_type: str
    page_count: int
    confidence_score: float

class AnalysisRequest(BaseModel):
    document_id: str
    questions: Optional[List[str]] = None
    analysis_type: str = "comprehensive"

class AnalysisResponse(BaseModel):
    analysis_id: str
    document_id: str
    status: str
    analysis: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

class QuestionRequest(BaseModel):
    document_id: str
    question: str

class QuestionResponse(BaseModel):
    answer: str
    confidence: float
    source: str

# Mock LLM responses
MOCK_RESPONSES = {
    "I-130": {
        "summary": "Form I-130 is a Petition for Alien Relative. This form is used by U.S. citizens and lawful permanent residents to establish a qualifying relationship with a foreign national who wishes to immigrate to the United States.",
        "key_information": {
            "form_number": "I-130",
            "deadlines": ["Submit within 30 days of qualifying event"],
            "required_documents": ["Birth certificates", "Marriage certificates", "Passport photos"],
            "fees": ["$535 filing fee"],
            "eligibility_requirements": ["Must be U.S. citizen or LPR", "Must have qualifying relationship"],
            "processing_time": "6-12 months"
        },
        "recommendations": [
            "Gather all required supporting documents before filing",
            "Ensure all forms are completed accurately",
            "Consider hiring an immigration attorney for complex cases",
            "Keep copies of all submitted documents",
            "Monitor case status online"
        ]
    },
    "I-485": {
        "summary": "Form I-485 is an Application to Register Permanent Residence or Adjust Status. This form allows eligible individuals to apply for a green card while remaining in the United States.",
        "key_information": {
            "form_number": "I-485",
            "deadlines": ["File before current status expires"],
            "required_documents": ["I-693 medical exam", "I-864 affidavit of support", "Passport photos"],
            "fees": ["$1,140 filing fee", "$85 biometrics fee"],
            "eligibility_requirements": ["Must be physically present in US", "Must have qualifying basis"],
            "processing_time": "8-14 months"
        },
        "recommendations": [
            "Complete medical examination before filing",
            "Ensure all supporting documents are current",
            "File concurrently with other required forms",
            "Maintain valid status during processing",
            "Prepare for biometrics appointment"
        ]
    },
    "I-765": {
        "summary": "Form I-765 is an Application for Employment Authorization Document (EAD). This form allows certain non-citizens to work legally in the United States.",
        "key_information": {
            "form_number": "I-765",
            "deadlines": ["File 90 days before current EAD expires"],
            "required_documents": ["Passport photos", "Current EAD (if renewing)", "Supporting documents"],
            "fees": ["$410 filing fee"],
            "eligibility_requirements": ["Must have valid immigration status", "Must be eligible for employment authorization"],
            "processing_time": "3-5 months"
        },
        "recommendations": [
            "File renewal applications early",
            "Include all required supporting documents",
            "Keep track of expiration dates",
            "Consider premium processing for urgent cases",
            "Notify employer of status changes"
        ]
    }
}

# API Endpoints

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "Immigration LLM API Demo",
        "version": "1.0.0",
        "mode": "DEMO - Using mock responses",
        "endpoints": {
            "upload": "/upload-pdf",
            "analyze": "/analyze-document",
            "ask": "/ask-question",
            "status": "/document-status/{document_id}",
            "health": "/health"
        }
    }

@app.post("/upload-pdf", response_model=DocumentUploadResponse)
async def upload_pdf(file: UploadFile = File(...)):
    """Upload and parse a PDF document (mock)"""
    try:
        # Validate file type
        if not file.filename.lower().endswith('.pdf'):
            raise HTTPException(status_code=400, detail="Only PDF files are allowed")
        
        # Generate unique document ID
        document_id = str(uuid.uuid4())
        
        # Mock document parsing
        document_type = "I-130"  # Default for demo
        if "485" in file.filename.lower():
            document_type = "I-485"
        elif "765" in file.filename.lower():
            document_type = "I-765"
        
        # Store in cache
        document_cache[document_id] = {
            "filename": file.filename,
            "document_type": document_type,
            "upload_time": datetime.now().isoformat(),
            "page_count": 5,
            "confidence_score": 0.95
        }
        
        logger.info(f"Mock upload successful: {file.filename} -> {document_id}")
        
        return DocumentUploadResponse(
            document_id=document_id,
            status="success",
            message="Document uploaded and parsed successfully (DEMO MODE)",
            document_type=document_type,
            page_count=5,
            confidence_score=0.95
        )
        
    except Exception as e:
        logger.error(f"Error uploading PDF: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error processing PDF: {str(e)}")

@app.post("/analyze-document", response_model=AnalysisResponse)
async def analyze_document(request: AnalysisRequest):
    """Analyze a parsed document with AI (mock)"""
    try:
        # Check if document exists
        if request.document_id not in document_cache:
            raise HTTPException(status_code=404, detail="Document not found")
        
        # Generate analysis ID
        analysis_id = str(uuid.uuid4())
        
        # Get document info
        doc_info = document_cache[request.document_id]
        document_type = doc_info["document_type"]
        
        # Get mock analysis
        analysis_data = MOCK_RESPONSES.get(document_type, MOCK_RESPONSES["I-130"]).copy()
        
        # Add mock Q&A if questions provided
        if request.questions:
            analysis_data["questions_answered"] = {}
            for question in request.questions:
                analysis_data["questions_answered"][question] = f"Based on {document_type}, here's a detailed answer to your question: {question}. This is a mock response for demonstration purposes."
        
        # Store analysis results
        analysis_cache[analysis_id] = {
            "document_id": request.document_id,
            "analysis_type": request.analysis_type,
            "analysis_data": analysis_data,
            "timestamp": datetime.now().isoformat()
        }
        
        logger.info(f"Mock analysis completed for document {request.document_id}")
        
        return AnalysisResponse(
            analysis_id=analysis_id,
            document_id=request.document_id,
            status="completed",
            analysis=analysis_data
        )
        
    except Exception as e:
        logger.error(f"Error analyzing document: {str(e)}")
        return AnalysisResponse(
            analysis_id="",
            document_id=request.document_id,
            status="error",
            error=str(e)
        )

@app.post("/ask-question", response_model=QuestionResponse)
async def ask_question(request: QuestionRequest):
    """Ask a specific question about a document (mock)"""
    try:
        # Check if document exists
        if request.document_id not in document_cache:
            raise HTTPException(status_code=404, detail="Document not found")
        
        # Get document info
        doc_info = document_cache[request.document_id]
        document_type = doc_info["document_type"]
        
        # Mock answer
        answer = f"Based on the {document_type} document, here's my answer: {request.question}. This is a mock response demonstrating how the AI would analyze your document and provide helpful guidance."
        
        logger.info(f"Mock question answered for document {request.document_id}")
        
        return QuestionResponse(
            answer=answer,
            confidence=0.9,
            source="mock_document_analysis"
        )
        
    except Exception as e:
        logger.error(f"Error answering question: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error answering question: {str(e)}")

@app.get("/document-status/{document_id}")
async def get_document_status(document_id: str):
    """Get status and information about a document"""
    try:
        if document_id not in document_cache:
            raise HTTPException(status_code=404, detail="Document not found")
        
        doc_info = document_cache[document_id]
        
        return {
            "document_id": document_id,
            "filename": doc_info["filename"],
            "upload_time": doc_info["upload_time"],
            "document_type": doc_info["document_type"],
            "page_count": doc_info["page_count"],
            "confidence_score": doc_info["confidence_score"],
            "status": "processed",
            "mode": "DEMO"
        }
        
    except Exception as e:
        logger.error(f"Error getting document status: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error getting document status: {str(e)}")

@app.get("/documents")
async def list_documents():
    """List all uploaded documents"""
    try:
        documents = []
        for doc_id, doc_info in document_cache.items():
            documents.append({
                "document_id": doc_id,
                "filename": doc_info["filename"],
                "upload_time": doc_info["upload_time"],
                "document_type": doc_info["document_type"],
                "page_count": doc_info["page_count"],
                "confidence_score": doc_info["confidence_score"]
            })
        
        return {"documents": documents}
        
    except Exception as e:
        logger.error(f"Error listing documents: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error listing documents: {str(e)}")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "mode": "DEMO",
        "timestamp": datetime.now().isoformat(),
        "documents_cached": len(document_cache),
        "analyses_cached": len(analysis_cache),
        "message": "API is running in demo mode with mock responses"
    }

if __name__ == "__main__":
    import uvicorn
    print("Starting Immigration LLM API Demo Server...")
    print("Mode: DEMO - Using mock responses")
    print("API Documentation: http://localhost:8000/docs")
    print("Health Check: http://localhost:8000/health")
    uvicorn.run(app, host="0.0.0.0", port=8000)
