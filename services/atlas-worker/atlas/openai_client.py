import os
import asyncio
import logging
from typing import List, Dict, Optional
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
import openai
from openai import OpenAI
from atlas.metrics import atlas_tokens_total, openai_reachable

# Configure logging
logger = logging.getLogger("atlas.openai")

# Environment variables
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
DEFAULT_MODEL = os.getenv("OPENAI_MODEL", "gpt-4.1")
FALLBACK_MODELS = os.getenv("OPENAI_FALLBACK_MODELS", "gpt-4o,gpt-4o-mini").split(",")
TOKEN_BUDGET_PER_RUN = int(os.getenv("TOKEN_BUDGET_PER_RUN", "12000"))

# Initialize OpenAI client
client = OpenAI(api_key=OPENAI_API_KEY)

# Define retryable exceptions
RETRYABLE_ERRORS = (
    openai.RateLimitError,  # Rate limit errors
    openai.APITimeoutError,  # Timeout errors
    openai.APIConnectionError,  # Connection errors
    openai.APIError,  # Generic API errors
)

def format_context(context: List[Dict]) -> str:
    """Format context chunks into a string for the prompt"""
    formatted_chunks = []
    
    for i, chunk in enumerate(context):
        text = chunk.get("text", "")
        source = chunk.get("source", "unknown")
        similarity = chunk.get("similarity", 0)
        
        formatted_chunks.append(
            f"[{i+1}] Source: {source} (similarity: {similarity:.2f})\n{text}\n"
        )
    
    return "\n\n".join(formatted_chunks)

def create_prompt(query: str, context: List[Dict]) -> str:
    """Create a prompt for the OpenAI model"""
    formatted_context = format_context(context)
    
    prompt = f"""You are Atlas, an expert architect specializing in technical system design. 
Your task is to create detailed, actionable architecture specifications based on the user's request.

# User Request
{query}

# Relevant Context
{formatted_context}

# Instructions
1. Create a comprehensive architecture specification addressing the user's request
2. Include appropriate diagrams using markdown or ascii art
3. Be specific about technologies, patterns, and implementation details
4. Provide clear rationale for major design decisions
5. Format the output as a Markdown document with proper headings, code blocks, and formatting
6. Include trade-offs and alternatives considered where appropriate

Output your architecture specification below:
"""
    return prompt

def estimate_tokens(prompt: str) -> int:
    """Roughly estimate the number of tokens in a prompt"""
    # A very rough estimation: 1 token ~= 4 chars in English
    return len(prompt) // 4

def count_tokens(prompt: str, completion: str) -> int:
    """Count tokens in prompt and completion (approximate)"""
    # A very rough estimation: 1 token ~= 4 chars in English
    prompt_tokens = len(prompt) // 4
    completion_tokens = len(completion) // 4
    return prompt_tokens + completion_tokens

@retry(
    retry=retry_if_exception_type(RETRYABLE_ERRORS),
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=60),
    reraise=True
)
async def call_openai_api(prompt: str, model: str = DEFAULT_MODEL) -> str:
    """Call the OpenAI API with retry logic"""
    try:
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "You are Atlas, an expert architect specializing in technical system design."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.2,
            max_tokens=4000,
            top_p=1,
            frequency_penalty=0,
            presence_penalty=0,
        )
        
        # Mark OpenAI as reachable
        openai_reachable.set(1)
        
        return response.choices[0].message.content
    except Exception as e:
        # Mark OpenAI as unreachable on error
        openai_reachable.set(0)
        logger.error(f"OpenAI API error with {model}: {str(e)}")
        raise

async def chat(prompt: str, context: List[Dict]) -> str:
    """
    Generate a response from OpenAI using fallback logic
    
    Uses a fallback chain if the primary model fails:
    DEFAULT_MODEL → FALLBACK_MODELS[0] → FALLBACK_MODELS[1] → ...
    
    Also tracks token usage.
    """
    # If this is a stub implementation, return the stub response
    if not OPENAI_API_KEY or OPENAI_API_KEY.startswith("sk-fake"):
        logger.warning("Using stub OpenAI implementation (no valid API key)")
        joined_ctx = "\n".join(c.get("text", "") for c in context)
        return f"[STUB RESPONSE - NO OPENAI KEY]\n\n[context]\n{joined_ctx}\n\n[response]\nSpec for: {prompt}"
    
    # Create the full prompt with context
    full_prompt = create_prompt(prompt, context)
    
    # Estimate token usage and check budget
    estimated_tokens = estimate_tokens(full_prompt) + 4000  # Prompt + max completion
    if estimated_tokens > TOKEN_BUDGET_PER_RUN:
        return f"Error: Estimated token usage ({estimated_tokens}) exceeds per-run budget ({TOKEN_BUDGET_PER_RUN})."
    
    # Try primary model first
    try:
        logger.info(f"Calling OpenAI with model: {DEFAULT_MODEL}")
        response = await call_openai_api(full_prompt, DEFAULT_MODEL)
        
        # Count tokens and update metrics
        total_tokens = count_tokens(full_prompt, response)
        atlas_tokens_total.inc(total_tokens)
        logger.info(f"Successfully generated response with {DEFAULT_MODEL} (tokens: {total_tokens})")
        
        return response
    except Exception as primary_error:
        logger.warning(f"Primary model {DEFAULT_MODEL} failed: {str(primary_error)}")
        
        # Try fallback models in sequence
        for fallback_model in FALLBACK_MODELS:
            try:
                logger.info(f"Trying fallback model: {fallback_model}")
                response = await call_openai_api(full_prompt, fallback_model)
                
                # Count tokens and update metrics
                total_tokens = count_tokens(full_prompt, response)
                atlas_tokens_total.inc(total_tokens)
                logger.info(f"Successfully generated response with fallback {fallback_model} (tokens: {total_tokens})")
                
                return response
            except Exception as fallback_error:
                logger.warning(f"Fallback model {fallback_model} failed: {str(fallback_error)}")
        
        # All models failed
        logger.error("All models failed, unable to generate response")
        error_message = f"""
# Error: All OpenAI Models Failed

We attempted to generate an architecture specification but encountered errors with all available models.

## Errors
- Primary model ({DEFAULT_MODEL}): {str(primary_error)}
- Fallback models: Failed to generate response

## Context
We were able to retrieve {len(context)} relevant context chunks, but could not process them.

## Recommendation
Please try again later or contact support if the issue persists.
"""
        return error_message