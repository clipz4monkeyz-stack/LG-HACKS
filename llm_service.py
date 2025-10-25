"""
LLM Service Layer for Immigration Document Analysis
Handles interactions with various LLM providers for document processing
"""

import openai
import anthropic
import os
import json
import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from enum import Enum
import asyncio
import aiohttp
from pdf_parser import ParsedDocument, PDFParser

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class LLMProvider(Enum):
    OPENAI = "openai"
    ANTHROPIC = "anthropic"
    LOCAL = "local"

@dataclass
class LLMResponse:
    """Response from LLM service"""
    content: str
    provider: LLMProvider
    model: str
    tokens_used: int
    processing_time: float
    confidence: float

@dataclass
class DocumentAnalysis:
    """Complete document analysis result"""
    summary: str
    key_information: Dict[str, Any]
    form_fields_analysis: List[Dict]
    recommendations: List[str]
    questions_answered: Dict[str, str]
    confidence_score: float

class LLMService:
    """Main LLM service class"""
    
    def __init__(self, provider: LLMProvider = LLMProvider.OPENAI):
        self.provider = provider
        self.parser = PDFParser()
        self._setup_provider()
    
    def _setup_provider(self):
        """Setup the selected LLM provider"""
        if self.provider == LLMProvider.OPENAI:
            openai.api_key = os.getenv('OPENAI_API_KEY')
            if not openai.api_key:
                raise ValueError("OPENAI_API_KEY environment variable not set")
        
        elif self.provider == LLMProvider.ANTHROPIC:
            anthropic.api_key = os.getenv('ANTHROPIC_API_KEY')
            if not anthropic.api_key:
                raise ValueError("ANTHROPIC_API_KEY environment variable not set")
    
    async def analyze_document(self, parsed_doc: ParsedDocument, 
                             questions: Optional[List[str]] = None) -> DocumentAnalysis:
        """
        Perform comprehensive analysis of a parsed document
        
        Args:
            parsed_doc: Parsed document object
            questions: Optional list of specific questions to answer
            
        Returns:
            DocumentAnalysis object with comprehensive results
        """
        try:
            # Generate document summary
            summary = await self._generate_summary(parsed_doc)
            
            # Extract key information
            key_info = await self._extract_key_information(parsed_doc)
            
            # Analyze form fields
            form_analysis = await self._analyze_form_fields(parsed_doc)
            
            # Generate recommendations
            recommendations = await self._generate_recommendations(parsed_doc)
            
            # Answer specific questions
            questions_answered = {}
            if questions:
                for question in questions:
                    answer = await self._answer_question(parsed_doc, question)
                    questions_answered[question] = answer
            
            # Calculate overall confidence
            confidence = self._calculate_analysis_confidence(parsed_doc, summary, key_info)
            
            return DocumentAnalysis(
                summary=summary,
                key_information=key_info,
                form_fields_analysis=form_analysis,
                recommendations=recommendations,
                questions_answered=questions_answered,
                confidence_score=confidence
            )
            
        except Exception as e:
            logger.error(f"Error analyzing document: {str(e)}")
            raise
    
    async def _generate_summary(self, parsed_doc: ParsedDocument) -> str:
        """Generate a comprehensive summary of the document"""
        prompt = f"""
        Analyze this immigration document and provide a comprehensive summary.
        
        Document Type: {parsed_doc.document_type}
        Page Count: {parsed_doc.metadata.page_count}
        
        Document Content:
        {parsed_doc.full_text[:4000]}  # Limit to first 4000 characters
        
        Please provide:
        1. Document purpose and type
        2. Key requirements and deadlines
        3. Required supporting documents
        4. Important instructions
        5. Potential issues or concerns
        
        Format your response as a clear, structured summary.
        """
        
        response = await self._call_llm(prompt, max_tokens=1000)
        return response.content
    
    async def _extract_key_information(self, parsed_doc: ParsedDocument) -> Dict[str, Any]:
        """Extract key information from the document"""
        prompt = f"""
        Extract key information from this immigration document in JSON format.
        
        Document Type: {parsed_doc.document_type}
        
        Document Content:
        {parsed_doc.full_text[:3000]}
        
        Please extract and return as JSON:
        {{
            "form_number": "form number if applicable",
            "deadlines": ["list of important deadlines"],
            "required_documents": ["list of required supporting documents"],
            "fees": ["list of fees and payment methods"],
            "eligibility_requirements": ["list of eligibility criteria"],
            "processing_time": "estimated processing time",
            "contact_information": "relevant contact details",
            "special_instructions": ["any special instructions or notes"]
        }}
        """
        
        response = await self._call_llm(prompt, max_tokens=800)
        
        try:
            return json.loads(response.content)
        except json.JSONDecodeError:
            # Fallback if JSON parsing fails
            return {"raw_response": response.content}
    
    async def _analyze_form_fields(self, parsed_doc: ParsedDocument) -> List[Dict]:
        """Analyze form fields and provide guidance"""
        if not parsed_doc.form_fields:
            return []
        
        form_analysis = []
        
        for field in parsed_doc.form_fields:
            prompt = f"""
            Analyze this form field from an immigration document:
            
            Field Name: {field.field_name}
            Field Type: {field.field_type}
            Current Value: {field.field_value}
            Document Type: {parsed_doc.document_type}
            
            Provide guidance on:
            1. What information should be entered
            2. Format requirements
            3. Common mistakes to avoid
            4. Required supporting documents
            
            Keep response concise and practical.
            """
            
            response = await self._call_llm(prompt, max_tokens=300)
            
            form_analysis.append({
                "field_name": field.field_name,
                "field_type": field.field_type,
                "guidance": response.content,
                "page_number": field.page_number
            })
        
        return form_analysis
    
    async def _generate_recommendations(self, parsed_doc: ParsedDocument) -> List[str]:
        """Generate actionable recommendations"""
        prompt = f"""
        Based on this immigration document, provide 5-7 actionable recommendations:
        
        Document Type: {parsed_doc.document_type}
        Document Content: {parsed_doc.full_text[:2000]}
        
        Focus on:
        - Next steps to take
        - Documents to gather
        - Deadlines to meet
        - Common pitfalls to avoid
        - Resources to consult
        
        Format as a numbered list of clear, actionable items.
        """
        
        response = await self._call_llm(prompt, max_tokens=600)
        return response.content.split('\n')
    
    async def _answer_question(self, parsed_doc: ParsedDocument, question: str) -> str:
        """Answer a specific question about the document"""
        prompt = f"""
        Answer this question based on the immigration document:
        
        Question: {question}
        
        Document Type: {parsed_doc.document_type}
        Document Content: {parsed_doc.full_text[:3000]}
        
        Provide a clear, accurate answer based on the document content.
        If the information is not available in the document, state that clearly.
        """
        
        response = await self._call_llm(prompt, max_tokens=400)
        return response.content
    
    async def _call_llm(self, prompt: str, max_tokens: int = 500) -> LLMResponse:
        """Call the configured LLM provider"""
        if self.provider == LLMProvider.OPENAI:
            return await self._call_openai(prompt, max_tokens)
        elif self.provider == LLMProvider.ANTHROPIC:
            return await self._call_anthropic(prompt, max_tokens)
        else:
            raise ValueError(f"Unsupported provider: {self.provider}")
    
    async def _call_openai(self, prompt: str, max_tokens: int) -> LLMResponse:
        """Call OpenAI API"""
        try:
            response = await openai.ChatCompletion.acreate(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": "You are an expert immigration assistant. Provide accurate, helpful information based on the provided documents."},
                    {"role": "user", "content": prompt}
                ],
                max_tokens=max_tokens,
                temperature=0.3
            )
            
            return LLMResponse(
                content=response.choices[0].message.content,
                provider=LLMProvider.OPENAI,
                model="gpt-4",
                tokens_used=response.usage.total_tokens,
                processing_time=0.0,  # OpenAI doesn't provide this
                confidence=0.9
            )
            
        except Exception as e:
            logger.error(f"OpenAI API error: {str(e)}")
            raise
    
    async def _call_anthropic(self, prompt: str, max_tokens: int) -> LLMResponse:
        """Call Anthropic API"""
        try:
            client = anthropic.AsyncAnthropic()
            response = await client.messages.create(
                model="claude-3-sonnet-20240229",
                max_tokens=max_tokens,
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )
            
            return LLMResponse(
                content=response.content[0].text,
                provider=LLMProvider.ANTHROPIC,
                model="claude-3-sonnet-20240229",
                tokens_used=response.usage.input_tokens + response.usage.output_tokens,
                processing_time=0.0,
                confidence=0.9
            )
            
        except Exception as e:
            logger.error(f"Anthropic API error: {str(e)}")
            raise
    
    def _calculate_analysis_confidence(self, parsed_doc: ParsedDocument, 
                                    summary: str, key_info: Dict) -> float:
        """Calculate confidence score for the analysis"""
        score = parsed_doc.confidence_score * 0.4  # Base document parsing confidence
        
        # Summary quality
        if len(summary) > 200:
            score += 0.2
        
        # Key information extraction
        if key_info and len(key_info) > 3:
            score += 0.2
        
        # Form fields analysis
        if parsed_doc.form_fields:
            score += 0.1
        
        # Document type recognition
        if parsed_doc.document_type != 'Unknown Document':
            score += 0.1
        
        return min(score, 1.0)
    
    async def translate_document(self, parsed_doc: ParsedDocument, 
                               target_language: str) -> str:
        """Translate document content to target language"""
        prompt = f"""
        Translate this immigration document content to {target_language}.
        Maintain the original formatting and structure.
        Keep legal terms accurate and provide context where needed.
        
        Document Content:
        {parsed_doc.full_text[:3000]}
        """
        
        response = await self._call_llm(prompt, max_tokens=1000)
        return response.content
    
    async def simplify_language(self, parsed_doc: ParsedDocument) -> str:
        """Simplify complex legal language for better understanding"""
        prompt = f"""
        Simplify this immigration document content to make it easier to understand.
        Replace complex legal terms with simpler explanations.
        Maintain accuracy while improving readability.
        
        Document Content:
        {parsed_doc.full_text[:3000]}
        """
        
        response = await self._call_llm(prompt, max_tokens=1000)
        return response.content
    
    async def generate_faq(self, parsed_doc: ParsedDocument) -> List[Dict[str, str]]:
        """Generate frequently asked questions based on the document"""
        prompt = f"""
        Generate 5-7 frequently asked questions about this immigration document.
        
        Document Type: {parsed_doc.document_type}
        Document Content: {parsed_doc.full_text[:2000]}
        
        Return as JSON array:
        [
            {{"question": "question text", "answer": "detailed answer"}},
            ...
        ]
        """
        
        response = await self._call_llm(prompt, max_tokens=800)
        
        try:
            return json.loads(response.content)
        except json.JSONDecodeError:
            return [{"question": "Error parsing FAQ", "answer": response.content}]

# Example usage
async def main():
    """Example usage of the LLM service"""
    try:
        # Initialize LLM service
        llm_service = LLMService(LLMProvider.OPENAI)
        
        # Parse a document
        parser = PDFParser()
        parsed_doc = parser.parse_pdf("sample_form.pdf")
        
        # Analyze the document
        analysis = await llm_service.analyze_document(
            parsed_doc, 
            questions=["What is the deadline for submission?", "What documents are required?"]
        )
        
        print(f"Document Summary: {analysis.summary}")
        print(f"Key Information: {json.dumps(analysis.key_information, indent=2)}")
        print(f"Recommendations: {analysis.recommendations}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(main())
