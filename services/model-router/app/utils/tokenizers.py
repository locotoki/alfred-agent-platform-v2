import logging
import re
from typing import Any, Dict, List, Optional, Union
import json

logger = logging.getLogger(__name__)

# Try to import tiktoken for accurate token counting
try:
    import tiktoken
    TIKTOKEN_AVAILABLE = True
except ImportError:
    logger.warning("tiktoken not available. Using fallback token counting methods.")
    TIKTOKEN_AVAILABLE = False


def get_tokenizer(model: str = "cl100k_base"):
    """Get a tokenizer for a specific model"""
    if not TIKTOKEN_AVAILABLE:
        return None
        
    try:
        # For GPT-4 and ChatGPT models
        if model.startswith(("gpt-4", "gpt-3.5")):
            return tiktoken.encoding_for_model(model)
            
        # For Claude models (using cl100k_base as best approximation)
        if model.startswith("claude"):
            return tiktoken.get_encoding("cl100k_base")
            
        # For other models, use cl100k as default
        return tiktoken.get_encoding(model)
    except Exception as e:
        logger.warning(f"Failed to get tokenizer for {model}: {e}")
        # Fallback to cl100k_base
        try:
            return tiktoken.get_encoding("cl100k_base")
        except Exception:
            return None


def count_tokens(text: str, model: str = "cl100k_base") -> int:
    """Count tokens for a given text string"""
    if not text:
        return 0
        
    # Use tiktoken if available
    if TIKTOKEN_AVAILABLE:
        tokenizer = get_tokenizer(model)
        if tokenizer:
            return len(tokenizer.encode(text))
            
    # Fallback methods
    # Simple approximation based on word count (very rough)
    words = len(re.findall(r'\b\w+\b', text))
    return int(words * 1.3)  # Assuming ~1.3 tokens per word on average


def count_message_tokens(messages: List[Dict[str, Any]], model: str = "cl100k_base") -> int:
    """Count tokens for a list of chat messages"""
    if not messages:
        return 0
        
    total_tokens = 0
    
    # Use tiktoken if available
    if TIKTOKEN_AVAILABLE:
        tokenizer = get_tokenizer(model)
        if tokenizer:
            # Count tokens in each message
            for message in messages:
                # Add tokens for message role (approximate)
                total_tokens += 4  # ~4 tokens for role field
                
                # Add tokens for content
                if "content" in message:
                    if isinstance(message["content"], str):
                        total_tokens += len(tokenizer.encode(message["content"]))
                    elif isinstance(message["content"], list):
                        # Handle multimodal content
                        for item in message["content"]:
                            if isinstance(item, dict) and "text" in item:
                                total_tokens += len(tokenizer.encode(item["text"]))
                            elif isinstance(item, dict) and "type" in item and item["type"] == "text":
                                content = item.get("text", "")
                                total_tokens += len(tokenizer.encode(content))
                
                # Add tokens for function calls if present
                if "function_call" in message:
                    if isinstance(message["function_call"], dict):
                        # Add tokens for function name
                        if "name" in message["function_call"]:
                            total_tokens += len(tokenizer.encode(message["function_call"]["name"]))
                            
                        # Add tokens for arguments
                        if "arguments" in message["function_call"]:
                            args = message["function_call"]["arguments"]
                            if isinstance(args, str):
                                total_tokens += len(tokenizer.encode(args))
                            elif isinstance(args, (dict, list)):
                                total_tokens += len(tokenizer.encode(json.dumps(args)))
            
            # Add few tokens for formatting
            total_tokens += 3  # ~3 tokens for formatting
            return total_tokens
            
    # Fallback method
    for message in messages:
        # Count tokens in content
        if "content" in message:
            if isinstance(message["content"], str):
                total_tokens += count_tokens(message["content"], model)
            elif isinstance(message["content"], list):
                for item in message["content"]:
                    if isinstance(item, dict) and "text" in item:
                        total_tokens += count_tokens(item["text"], model)
                    elif isinstance(item, dict) and "type" in item and item["type"] == "text":
                        content = item.get("text", "")
                        total_tokens += count_tokens(content, model)
                        
        # Count tokens in function calls
        if "function_call" in message:
            if isinstance(message["function_call"], dict):
                if "name" in message["function_call"]:
                    total_tokens += count_tokens(message["function_call"]["name"], model)
                if "arguments" in message["function_call"]:
                    args = message["function_call"]["arguments"]
                    if isinstance(args, str):
                        total_tokens += count_tokens(args, model)
                    elif isinstance(args, (dict, list)):
                        total_tokens += count_tokens(json.dumps(args), model)
                        
    # Add tokens for formatting
    total_tokens += len(messages) * 4  # Approximate overhead per message
    
    return total_tokens


def truncate_text_to_token_limit(text: str, max_tokens: int, model: str = "cl100k_base") -> str:
    """Truncate text to stay within a token limit"""
    if not text:
        return ""
        
    # If text is already within limits, return it
    current_tokens = count_tokens(text, model)
    if current_tokens <= max_tokens:
        return text
        
    # Use tiktoken for accurate truncation if available
    if TIKTOKEN_AVAILABLE:
        tokenizer = get_tokenizer(model)
        if tokenizer:
            tokens = tokenizer.encode(text)
            truncated_tokens = tokens[:max_tokens]
            return tokenizer.decode(truncated_tokens)
            
    # Fallback method: truncate by characters
    # Estimate chars per token (very rough)
    chars_per_token = len(text) / current_tokens
    char_limit = int(max_tokens * chars_per_token)
    
    # Truncate text
    truncated_text = text[:char_limit]
    
    # Try to end at a sentence or word boundary
    last_period = truncated_text.rfind('.')
    last_space = truncated_text.rfind(' ')
    
    if last_period > len(truncated_text) * 0.7:  # If period is in the latter 30%
        return truncated_text[:last_period + 1]
    elif last_space > -1:
        return truncated_text[:last_space]
    
    return truncated_text