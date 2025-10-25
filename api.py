"""
FastAPI Backend for Immigration LLM Integration
Provides RESTful API endpoints for document processing and AI analysis
"""

from fastapi import FastAPI, File, UploadFile, HTTPException, Depends, BackgroundTasks
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
import aiofiles

from pdf_parser import PDFParser, ParsedDocument
from llm_service import LLMService, LLMProvider, DocumentAnalysis

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Immigration LLM API",
    description="AI-powered immigration document processing and analysis",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global instances
pdf_parser = PDFParser()
llm_service = LLMService(LLMProvider.OPENAI)

# In-memory storage for demo (use database in production)
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
    analysis_type: str = "comprehensive"  # comprehensive, summary, qa, translate, simplify

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

class TranslationRequest(BaseModel):
    document_id: str
    target_language: str

class TranslationResponse(BaseModel):
    translated_content: str
    target_language: str
    confidence: float

# API Endpoints

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "Immigration LLM API",
        "version": "1.0.0",
        "endpoints": {
            "upload": "/upload-pdf",
            "analyze": "/analyze-document",
            "ask": "/ask-question",
            "translate": "/translate-document",
            "simplify": "/simplify-document",
            "status": "/document-status/{document_id}"
        }
    }

@app.post("/upload-pdf", response_model=DocumentUploadResponse)
async def upload_pdf(file: UploadFile = File(...)):
    """
    Upload and parse a PDF document
    
    Args:
        file: PDF file to upload
        
    Returns:
        DocumentUploadResponse with parsing results
    """
    try:
        # Validate file type
        if not file.filename.lower().endswith('.pdf'):
            raise HTTPException(status_code=400, detail="Only PDF files are allowed")
        
        # Generate unique document ID
        document_id = str(uuid.uuid4())
        
        # Read file content
        content = await file.read()
        
        # Validate file size (50MB limit)
        if len(content) > 50 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="File size exceeds 50MB limit")
        
        # Parse PDF
        parsed_doc = pdf_parser.parse_pdf_from_bytes(content)
        
        # Store in cache
        document_cache[document_id] = {
            "parsed_doc": parsed_doc,
            "filename": file.filename,
            "upload_time": datetime.now().isoformat(),
            "file_size": len(content)
        }
        
        # Generate summary
        summary = pdf_parser.get_document_summary(parsed_doc)
        
        logger.info(f"Successfully parsed document {document_id}: {file.filename}")
        
        return DocumentUploadResponse(
            document_id=document_id,
            status="success",
            message="Document uploaded and parsed successfully",
            document_type=parsed_doc.document_type,
            page_count=parsed_doc.metadata.page_count,
            confidence_score=parsed_doc.confidence_score
        )
        
    except Exception as e:
        logger.error(f"Error uploading PDF: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error processing PDF: {str(e)}")

@app.post("/analyze-document", response_model=AnalysisResponse)
async def analyze_document(request: AnalysisRequest, background_tasks: BackgroundTasks):
    """
    Analyze a parsed document with AI
    
    Args:
        request: Analysis request with document ID and options
        
    Returns:
        AnalysisResponse with analysis results
    """
    try:
        # Check if document exists
        if request.document_id not in document_cache:
            raise HTTPException(status_code=404, detail="Document not found")
        
        # Generate analysis ID
        analysis_id = str(uuid.uuid4())
        
        # Get parsed document
        parsed_doc = document_cache[request.document_id]["parsed_doc"]
        
        # Perform analysis based on type
        if request.analysis_type == "comprehensive":
            analysis = await llm_service.analyze_document(parsed_doc, request.questions)
            analysis_data = {
                "summary": analysis.summary,
                "key_information": analysis.key_information,
                "form_fields_analysis": analysis.form_fields_analysis,
                "recommendations": analysis.recommendations,
                "questions_answered": analysis.questions_answered,
                "confidence_score": analysis.confidence_score
            }
        elif request.analysis_type == "summary":
            summary = await llm_service._generate_summary(parsed_doc)
            analysis_data = {"summary": summary}
        elif request.analysis_type == "qa" and request.questions:
            questions_answered = {}
            for question in request.questions:
                answer = await llm_service._answer_question(parsed_doc, question)
                questions_answered[question] = answer
            analysis_data = {"questions_answered": questions_answered}
        else:
            raise HTTPException(status_code=400, detail="Invalid analysis type")
        
        # Store analysis results
        analysis_cache[analysis_id] = {
            "document_id": request.document_id,
            "analysis_type": request.analysis_type,
            "analysis_data": analysis_data,
            "timestamp": datetime.now().isoformat()
        }
        
        logger.info(f"Analysis completed for document {request.document_id}")
        
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
    """
    Ask a specific question about a document
    
    Args:
        request: Question request with document ID and question
        
    Returns:
        QuestionResponse with answer
    """
    try:
        # Check if document exists
        if request.document_id not in document_cache:
            raise HTTPException(status_code=404, detail="Document not found")
        
        # Get parsed document
        parsed_doc = document_cache[request.document_id]["parsed_doc"]
        
        # Get answer from LLM
        answer = await llm_service._answer_question(parsed_doc, request.question)
        
        # Calculate confidence (simplified)
        confidence = parsed_doc.confidence_score * 0.8
        
        logger.info(f"Question answered for document {request.document_id}")
        
        return QuestionResponse(
            answer=answer,
            confidence=confidence,
            source="document_analysis"
        )
        
    except Exception as e:
        logger.error(f"Error answering question: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error answering question: {str(e)}")

@app.post("/translate-document", response_model=TranslationResponse)
async def translate_document(request: TranslationRequest):
    """
    Translate document content to target language
    
    Args:
        request: Translation request with document ID and target language
        
    Returns:
        TranslationResponse with translated content
    """
    try:
        # Check if document exists
        if request.document_id not in document_cache:
            raise HTTPException(status_code=404, detail="Document not found")
        
        # Get parsed document
        parsed_doc = document_cache[request.document_id]["parsed_doc"]
        
        # Translate document
        translated_content = await llm_service.translate_document(
            parsed_doc, 
            request.target_language
        )
        
        logger.info(f"Document translated to {request.target_language}")
        
        return TranslationResponse(
            translated_content=translated_content,
            target_language=request.target_language,
            confidence=0.9
        )
        
    except Exception as e:
        logger.error(f"Error translating document: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error translating document: {str(e)}")

@app.post("/simplify-document")
async def simplify_document(document_id: str):
    """
    Simplify complex legal language in document
    
    Args:
        document_id: ID of the document to simplify
        
    Returns:
        Simplified document content
    """
    try:
        # Check if document exists
        if document_id not in document_cache:
            raise HTTPException(status_code=404, detail="Document not found")
        
        # Get parsed document
        parsed_doc = document_cache[document_id]["parsed_doc"]
        
        # Simplify document
        simplified_content = await llm_service.simplify_language(parsed_doc)
        
        logger.info(f"Document simplified for document {document_id}")
        
        return {
            "document_id": document_id,
            "simplified_content": simplified_content,
            "confidence": 0.9
        }
        
    except Exception as e:
        logger.error(f"Error simplifying document: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error simplifying document: {str(e)}")

@app.get("/document-status/{document_id}")
async def get_document_status(document_id: str):
    """
    Get status and information about a document
    
    Args:
        document_id: ID of the document
        
    Returns:
        Document status and metadata
    """
    try:
        if document_id not in document_cache:
            raise HTTPException(status_code=404, detail="Document not found")
        
        doc_info = document_cache[document_id]
        parsed_doc = doc_info["parsed_doc"]
        
        # Get document summary
        summary = pdf_parser.get_document_summary(parsed_doc)
        
        return {
            "document_id": document_id,
            "filename": doc_info["filename"],
            "upload_time": doc_info["upload_time"],
            "file_size": doc_info["file_size"],
            "document_type": parsed_doc.document_type,
            "page_count": parsed_doc.metadata.page_count,
            "confidence_score": parsed_doc.confidence_score,
            "summary": summary,
            "has_form_fields": len(parsed_doc.form_fields) > 0,
            "has_tables": len(parsed_doc.tables) > 0,
            "has_images": len(parsed_doc.images_info) > 0
        }
        
    except Exception as e:
        logger.error(f"Error getting document status: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error getting document status: {str(e)}")

@app.get("/documents")
async def list_documents():
    """
    List all uploaded documents
    
    Returns:
        List of document information
    """
    try:
        documents = []
        for doc_id, doc_info in document_cache.items():
            parsed_doc = doc_info["parsed_doc"]
            summary = pdf_parser.get_document_summary(parsed_doc)
            
            documents.append({
                "document_id": doc_id,
                "filename": doc_info["filename"],
                "upload_time": doc_info["upload_time"],
                "document_type": parsed_doc.document_type,
                "page_count": parsed_doc.metadata.page_count,
                "confidence_score": parsed_doc.confidence_score,
                "summary": summary
            })
        
        return {"documents": documents}
        
    except Exception as e:
        logger.error(f"Error listing documents: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error listing documents: {str(e)}")

@app.delete("/documents/{document_id}")
async def delete_document(document_id: str):
    """
    Delete a document and its analysis
    
    Args:
        document_id: ID of the document to delete
        
    Returns:
        Success message
    """
    try:
        if document_id not in document_cache:
            raise HTTPException(status_code=404, detail="Document not found")
        
        # Remove document
        del document_cache[document_id]
        
        # Remove related analyses
        analyses_to_remove = [
            analysis_id for analysis_id, analysis in analysis_cache.items()
            if analysis["document_id"] == document_id
        ]
        
        for analysis_id in analyses_to_remove:
            del analysis_cache[analysis_id]
        
        logger.info(f"Document {document_id} deleted successfully")
        
        return {"message": "Document deleted successfully"}
        
    except Exception as e:
        logger.error(f"Error deleting document: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error deleting document: {str(e)}")

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "documents_cached": len(document_cache),
        "analyses_cached": len(analysis_cache)
    }

# Error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.detail, "status_code": exc.status_code}
    )

@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    logger.error(f"Unhandled exception: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={"error": "Internal server error", "status_code": 500}
    )

# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    logger.info("Starting Immigration LLM API")
    
    # Check environment variables
    required_env_vars = ["OPENAI_API_KEY"]
    missing_vars = [var for var in required_env_vars if not os.getenv(var)]
    
    if missing_vars:
        logger.warning(f"Missing environment variables: {missing_vars}")
        logger.warning("Some features may not work properly")

# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down Immigration LLM API")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
