import logging
import re
import json
from typing import Dict, List, Any, Optional
import base64
from io import BytesIO
import math
import tiktoken
from PIL import Image

from app.models.models import ContentType, RoutingRequest, ContentItem
from app.core.config import settings

logger = logging.getLogger(__name__)

class RequestAnalyzer:
    """Analyzes request content and context to determine characteristics"""
    
    def __init__(self):
        """Initialize the request analyzer"""
        # Try to load tokenizer
        self.tokenizer = None
        try:
            self.tokenizer = tiktoken.get_encoding("cl100k_base")
        except Exception as e:
            logger.warning(f"Failed to load tiktoken: {e}. Token counting will be approximate.")
        
        # Regex patterns for content detection
        self.patterns = {
            "image_url": re.compile(r'^https?://.*\.(jpg|jpeg|png|gif|bmp|webp|svg)$', re.IGNORECASE),
            "code_block": re.compile(r'```[\w]*\n[\s\S]*?\n```'),
            "json_block": re.compile(r'```json\n[\s\S]*?\n```'),
            "html_block": re.compile(r'```html\n[\s\S]*?\n```'),
            "xml_block": re.compile(r'```xml\n[\s\S]*?\n```'),
            "csv_block": re.compile(r'```csv\n[\s\S]*?\n```'),
            "table": re.compile(r'\|[\s\S]*\|\n\|[\s\-:]*\|\n\|[\s\S]*\|'),
            "url": re.compile(r'https?://\S+'),
            "email": re.compile(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
            "base64_image": re.compile(r'data:image\/[^;]+;base64,[a-zA-Z0-9+\/]+=*')
        }
        
    def estimate_token_count(self, text: str) -> int:
        """Estimate token count for a text string"""
        if self.tokenizer:
            return len(self.tokenizer.encode(text))
        else:
            # Fallback estimation: ~4 characters per token
            return len(text) // 4
            
    def detect_content_type(self, content: str) -> ContentType:
        """Detect the type of content from a string"""
        # Check for base64 encoded images
        if self.patterns["base64_image"].search(content):
            return ContentType.IMAGE
            
        # Check for image URLs
        if self.patterns["image_url"].search(content):
            return ContentType.IMAGE
            
        # Check for code blocks
        if self.patterns["code_block"].search(content):
            return ContentType.CODE
            
        # Check for specific code types
        if self.patterns["json_block"].search(content):
            return ContentType.JSON
            
        if self.patterns["html_block"].search(content):
            return ContentType.HTML
            
        if self.patterns["xml_block"].search(content):
            return ContentType.XML
            
        if self.patterns["csv_block"].search(content):
            return ContentType.CSV
            
        # Default to text
        return ContentType.TEXT
        
    def extract_image_metadata(self, image_data: str) -> Dict[str, Any]:
        """Extract metadata from base64 encoded image"""
        metadata = {}
        
        try:
            # Extract actual base64 data after the header
            if "base64," in image_data:
                base64_data = image_data.split("base64,")[1]
            else:
                base64_data = image_data
                
            # Decode base64 data
            image_bytes = base64.b64decode(base64_data)
            image = Image.open(BytesIO(image_bytes))
            
            # Extract metadata
            metadata["width"] = image.width
            metadata["height"] = image.height
            metadata["format"] = image.format
            metadata["size"] = len(image_bytes)
            metadata["aspect_ratio"] = image.width / image.height if image.height > 0 else 0
            
            return metadata
        except Exception as e:
            logger.warning(f"Failed to extract image metadata: {e}")
            return metadata
            
    def estimate_complexity(self, request: RoutingRequest) -> float:
        """Estimate the complexity of the request on a scale of 0-1"""
        complexity = 0.0
        
        # Analyze content
        for item in request.content:
            # Add complexity based on content type
            if item.type == ContentType.TEXT:
                # Add complexity based on text length
                text_length = len(item.content)
                complexity += min(0.3, text_length / 10000 * 0.3)
                
                # Check for complex elements in text
                if self.patterns["code_block"].search(item.content):
                    complexity += 0.1
                if self.patterns["table"].search(item.content):
                    complexity += 0.1
                if self.patterns["url"].findall(item.content):
                    complexity += 0.05
                    
            elif item.type == ContentType.IMAGE:
                complexity += 0.2
                
            elif item.type == ContentType.CODE:
                complexity += 0.2
                
            elif item.type == ContentType.JSON:
                complexity += 0.15
                
            elif item.type == ContentType.HTML:
                complexity += 0.15
                
            elif item.type == ContentType.XML:
                complexity += 0.15
                
            elif item.type == ContentType.CSV:
                complexity += 0.1
                
            elif item.type == ContentType.PDF:
                complexity += 0.25
                
            elif item.type == ContentType.DOCUMENT:
                complexity += 0.25
                
        # Normalize complexity to 0-1 range
        complexity = min(1.0, complexity)
        
        return complexity
        
    def analyze_request(self, request: RoutingRequest) -> Dict[str, Any]:
        """Perform comprehensive analysis of a request"""
        analysis = {
            "token_count": 0,
            "content_types": [],
            "complexity": 0.0,
            "image_count": 0,
            "code_blocks": 0,
            "tables": 0,
            "urls": 0,
            "large_contents": 0
        }
        
        # Analyze each content item
        for item in request.content:
            # Track content types
            if item.type not in analysis["content_types"]:
                analysis["content_types"].append(item.type)
                
            # Process based on content type
            if item.type == ContentType.TEXT:
                # Estimate token count
                token_count = self.estimate_token_count(item.content)
                analysis["token_count"] += token_count
                
                # Check for large content
                if token_count > 1000:
                    analysis["large_contents"] += 1
                    
                # Count code blocks
                code_blocks = len(self.patterns["code_block"].findall(item.content))
                analysis["code_blocks"] += code_blocks
                
                # Count tables
                tables = len(self.patterns["table"].findall(item.content))
                analysis["tables"] += tables
                
                # Count URLs
                urls = len(self.patterns["url"].findall(item.content))
                analysis["urls"] += urls
                
            elif item.type == ContentType.IMAGE:
                analysis["image_count"] += 1
                
            elif item.type == ContentType.CODE:
                analysis["code_blocks"] += 1
                if isinstance(item.content, str):
                    analysis["token_count"] += self.estimate_token_count(item.content)
                    
            elif item.type in [ContentType.JSON, ContentType.HTML, ContentType.XML, ContentType.CSV]:
                if isinstance(item.content, str):
                    analysis["token_count"] += self.estimate_token_count(item.content)
                elif isinstance(item.content, (dict, list)):
                    analysis["token_count"] += self.estimate_token_count(json.dumps(item.content))
                    
        # Estimate complexity
        analysis["complexity"] = self.estimate_complexity(request)
        
        return analysis
        
    def process_raw_text(self, text: str) -> List[ContentItem]:
        """Process raw text and extract structured content items"""
        content_items = []
        
        # Check for image URLs
        image_urls = self.patterns["image_url"].findall(text)
        for url in image_urls:
            content_items.append(
                ContentItem(
                    type=ContentType.IMAGE,
                    content=url,
                    metadata={"source": "url"}
                )
            )
            
        # Check for base64 images
        base64_images = self.patterns["base64_image"].findall(text)
        for img in base64_images:
            content_items.append(
                ContentItem(
                    type=ContentType.IMAGE,
                    content=img,
                    metadata=self.extract_image_metadata(img)
                )
            )
            
        # Extract code blocks
        code_blocks = self.patterns["code_block"].findall(text)
        for block in code_blocks:
            # Determine type of code block
            if block.startswith("```json"):
                content_type = ContentType.JSON
            elif block.startswith("```html"):
                content_type = ContentType.HTML
            elif block.startswith("```xml"):
                content_type = ContentType.XML
            elif block.startswith("```csv"):
                content_type = ContentType.CSV
            else:
                content_type = ContentType.CODE
                
            # Extract content without the backticks and language identifier
            lines = block.split("\n")
            content = "\n".join(lines[1:-1])
            
            content_items.append(
                ContentItem(
                    type=content_type,
                    content=content,
                    metadata={"language": lines[0].replace("```", "")}
                )
            )
            
        # Add remaining text
        # Remove code blocks and base64 images to avoid duplication
        for pattern in [self.patterns["code_block"], self.patterns["base64_image"]]:
            text = pattern.sub("", text)
            
        # Only add text if there's something left
        if text.strip():
            content_items.append(
                ContentItem(
                    type=ContentType.TEXT,
                    content=text.strip()
                )
            )
            
        return content_items