"""
PDF Parser Module for Immigration Document Processing
Handles PDF text extraction, form field detection, and document analysis
"""

import fitz  # PyMuPDF
import pdfplumber
import io
import base64
from typing import Dict, List, Optional, Tuple
import logging
from dataclasses import dataclass
import json

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class DocumentMetadata:
    """Metadata extracted from PDF document"""
    title: str
    author: str
    subject: str
    creator: str
    producer: str
    creation_date: str
    modification_date: str
    page_count: int
    file_size: int

@dataclass
class FormField:
    """Form field information"""
    field_name: str
    field_type: str
    field_value: str
    coordinates: Tuple[float, float, float, float]
    page_number: int

@dataclass
class TableData:
    """Table data extracted from PDF"""
    table_text: str
    table_data: List[List[str]]
    coordinates: Tuple[float, float, float, float]
    page_number: int

@dataclass
class ParsedDocument:
    """Complete parsed document structure"""
    metadata: DocumentMetadata
    full_text: str
    pages_text: List[str]
    form_fields: List[FormField]
    tables: List[TableData]
    images_info: List[Dict]
    document_type: str
    confidence_score: float

class PDFParser:
    """Main PDF parsing class"""
    
    def __init__(self):
        self.supported_formats = ['.pdf']
        self.max_file_size = 50 * 1024 * 1024  # 50MB limit
        
    def parse_pdf(self, pdf_path: str) -> ParsedDocument:
        """
        Parse a PDF file and extract all relevant information
        
        Args:
            pdf_path: Path to the PDF file
            
        Returns:
            ParsedDocument object with all extracted data
        """
        try:
            # Open PDF with PyMuPDF
            doc = fitz.open(pdf_path)
            
            # Extract metadata
            metadata = self._extract_metadata(doc)
            
            # Extract text from all pages
            full_text, pages_text = self._extract_text(doc)
            
            # Extract form fields
            form_fields = self._extract_form_fields(doc)
            
            # Extract tables using pdfplumber
            tables = self._extract_tables(pdf_path)
            
            # Extract images information
            images_info = self._extract_images_info(doc)
            
            # Determine document type
            document_type = self._classify_document(full_text)
            
            # Calculate confidence score
            confidence_score = self._calculate_confidence(full_text, form_fields, tables)
            
            doc.close()
            
            return ParsedDocument(
                metadata=metadata,
                full_text=full_text,
                pages_text=pages_text,
                form_fields=form_fields,
                tables=tables,
                images_info=images_info,
                document_type=document_type,
                confidence_score=confidence_score
            )
            
        except Exception as e:
            logger.error(f"Error parsing PDF {pdf_path}: {str(e)}")
            raise
    
    def parse_pdf_from_bytes(self, pdf_bytes: bytes) -> ParsedDocument:
        """
        Parse PDF from bytes data
        
        Args:
            pdf_bytes: PDF file content as bytes
            
        Returns:
            ParsedDocument object
        """
        try:
            # Create a temporary file-like object
            pdf_stream = io.BytesIO(pdf_bytes)
            doc = fitz.open(stream=pdf_stream, filetype="pdf")
            
            # Extract metadata
            metadata = self._extract_metadata(doc)
            
            # Extract text from all pages
            full_text, pages_text = self._extract_text(doc)
            
            # Extract form fields
            form_fields = self._extract_form_fields(doc)
            
            # Extract tables using pdfplumber
            tables = self._extract_tables_from_bytes(pdf_bytes)
            
            # Extract images information
            images_info = self._extract_images_info(doc)
            
            # Determine document type
            document_type = self._classify_document(full_text)
            
            # Calculate confidence score
            confidence_score = self._calculate_confidence(full_text, form_fields, tables)
            
            doc.close()
            
            return ParsedDocument(
                metadata=metadata,
                full_text=full_text,
                pages_text=pages_text,
                form_fields=form_fields,
                tables=tables,
                images_info=images_info,
                document_type=document_type,
                confidence_score=confidence_score
            )
            
        except Exception as e:
            logger.error(f"Error parsing PDF from bytes: {str(e)}")
            raise
    
    def _extract_metadata(self, doc: fitz.Document) -> DocumentMetadata:
        """Extract metadata from PDF document"""
        metadata = doc.metadata
        
        return DocumentMetadata(
            title=metadata.get('title', ''),
            author=metadata.get('author', ''),
            subject=metadata.get('subject', ''),
            creator=metadata.get('creator', ''),
            producer=metadata.get('producer', ''),
            creation_date=metadata.get('creationDate', ''),
            modification_date=metadata.get('modDate', ''),
            page_count=doc.page_count,
            file_size=0  # Will be set by caller
        )
    
    def _extract_text(self, doc: fitz.Document) -> Tuple[str, List[str]]:
        """Extract text from all pages"""
        full_text = ""
        pages_text = []
        
        for page_num in range(doc.page_count):
            page = doc[page_num]
            page_text = page.get_text()
            pages_text.append(page_text)
            full_text += page_text + "\n"
        
        return full_text.strip(), pages_text
    
    def _extract_form_fields(self, doc: fitz.Document) -> List[FormField]:
        """Extract form fields from PDF"""
        form_fields = []
        
        for page_num in range(doc.page_count):
            page = doc[page_num]
            widgets = page.widgets()
            
            for widget in widgets:
                field = FormField(
                    field_name=widget.field_name or f"field_{len(form_fields)}",
                    field_type=widget.field_type_string,
                    field_value=widget.field_value or "",
                    coordinates=widget.rect,
                    page_number=page_num + 1
                )
                form_fields.append(field)
        
        return form_fields
    
    def _extract_tables(self, pdf_path: str) -> List[TableData]:
        """Extract tables from PDF using pdfplumber"""
        tables = []
        
        try:
            with pdfplumber.open(pdf_path) as pdf:
                for page_num, page in enumerate(pdf.pages):
                    page_tables = page.extract_tables()
                    
                    for table in page_tables:
                        if table and len(table) > 1:  # Ensure table has data
                            table_text = "\n".join(["\t".join(row) for row in table])
                            tables.append(TableData(
                                table_text=table_text,
                                table_data=table,
                                coordinates=(0, 0, 0, 0),  # pdfplumber doesn't provide coordinates
                                page_number=page_num + 1
                            ))
        except Exception as e:
            logger.warning(f"Error extracting tables: {str(e)}")
        
        return tables
    
    def _extract_tables_from_bytes(self, pdf_bytes: bytes) -> List[TableData]:
        """Extract tables from PDF bytes using pdfplumber"""
        tables = []
        
        try:
            pdf_stream = io.BytesIO(pdf_bytes)
            with pdfplumber.open(pdf_stream) as pdf:
                for page_num, page in enumerate(pdf.pages):
                    page_tables = page.extract_tables()
                    
                    for table in page_tables:
                        if table and len(table) > 1:
                            table_text = "\n".join(["\t".join(row) for row in table])
                            tables.append(TableData(
                                table_text=table_text,
                                table_data=table,
                                coordinates=(0, 0, 0, 0),
                                page_number=page_num + 1
                            ))
        except Exception as e:
            logger.warning(f"Error extracting tables from bytes: {str(e)}")
        
        return tables
    
    def _extract_images_info(self, doc: fitz.Document) -> List[Dict]:
        """Extract information about images in the document"""
        images_info = []
        
        for page_num in range(doc.page_count):
            page = doc[page_num]
            image_list = page.get_images()
            
            for img_index, img in enumerate(image_list):
                xref = img[0]
                pix = fitz.Pixmap(doc, xref)
                
                if pix.n - pix.alpha < 4:  # GRAY or RGB
                    images_info.append({
                        'page_number': page_num + 1,
                        'image_index': img_index,
                        'width': pix.width,
                        'height': pix.height,
                        'colorspace': pix.colorspace.name if pix.colorspace else 'Unknown',
                        'xref': xref
                    })
                
                pix = None
        
        return images_info
    
    def _classify_document(self, text: str) -> str:
        """Classify the type of immigration document"""
        text_lower = text.lower()
        
        # USCIS Form patterns
        form_patterns = {
            'I-130': ['i-130', 'petition for alien relative'],
            'I-485': ['i-485', 'application to register permanent residence'],
            'I-765': ['i-765', 'application for employment authorization'],
            'I-821D': ['i-821d', 'daca', 'deferred action'],
            'I-90': ['i-90', 'application to replace permanent resident card'],
            'N-400': ['n-400', 'application for naturalization'],
            'I-864': ['i-864', 'affidavit of support'],
            'I-693': ['i-693', 'report of medical examination'],
            'G-1145': ['g-1145', 'e-notification'],
            'I-131': ['i-131', 'application for travel document']
        }
        
        for form_type, patterns in form_patterns.items():
            if any(pattern in text_lower for pattern in patterns):
                return form_type
        
        # General document types
        if 'passport' in text_lower:
            return 'Passport'
        elif 'birth certificate' in text_lower:
            return 'Birth Certificate'
        elif 'marriage certificate' in text_lower:
            return 'Marriage Certificate'
        elif 'divorce decree' in text_lower:
            return 'Divorce Decree'
        elif 'employment' in text_lower and 'authorization' in text_lower:
            return 'Employment Authorization'
        else:
            return 'Unknown Document'
    
    def _calculate_confidence(self, text: str, form_fields: List[FormField], tables: List[TableData]) -> float:
        """Calculate confidence score for document parsing"""
        score = 0.0
        
        # Text extraction quality
        if len(text.strip()) > 100:
            score += 0.3
        
        # Form fields found
        if form_fields:
            score += 0.2
        
        # Tables found
        if tables:
            score += 0.2
        
        # Document classification
        if self._classify_document(text) != 'Unknown Document':
            score += 0.3
        
        return min(score, 1.0)
    
    def extract_text_chunks(self, text: str, chunk_size: int = 1000, overlap: int = 200) -> List[str]:
        """
        Split text into chunks for LLM processing
        
        Args:
            text: Full text to chunk
            chunk_size: Maximum size of each chunk
            overlap: Overlap between chunks
            
        Returns:
            List of text chunks
        """
        chunks = []
        start = 0
        
        while start < len(text):
            end = start + chunk_size
            chunk = text[start:end]
            
            # Try to break at sentence boundary
            if end < len(text):
                last_period = chunk.rfind('.')
                last_newline = chunk.rfind('\n')
                break_point = max(last_period, last_newline)
                
                if break_point > start + chunk_size // 2:
                    chunk = text[start:start + break_point + 1]
                    end = start + break_point + 1
            
            chunks.append(chunk.strip())
            start = end - overlap
        
        return chunks
    
    def validate_pdf(self, pdf_path: str) -> bool:
        """Validate if PDF can be processed"""
        try:
            doc = fitz.open(pdf_path)
            doc.close()
            return True
        except:
            return False
    
    def get_document_summary(self, parsed_doc: ParsedDocument) -> Dict:
        """Generate a summary of the parsed document"""
        return {
            'document_type': parsed_doc.document_type,
            'page_count': parsed_doc.metadata.page_count,
            'form_fields_count': len(parsed_doc.form_fields),
            'tables_count': len(parsed_doc.tables),
            'images_count': len(parsed_doc.images_info),
            'text_length': len(parsed_doc.full_text),
            'confidence_score': parsed_doc.confidence_score,
            'has_form_fields': len(parsed_doc.form_fields) > 0,
            'has_tables': len(parsed_doc.tables) > 0,
            'has_images': len(parsed_doc.images_info) > 0
        }

# Example usage
if __name__ == "__main__":
    parser = PDFParser()
    
    # Example: Parse a PDF file
    try:
        parsed_doc = parser.parse_pdf("sample_form.pdf")
        summary = parser.get_document_summary(parsed_doc)
        print(f"Document Summary: {json.dumps(summary, indent=2)}")
    except Exception as e:
        print(f"Error: {e}")
