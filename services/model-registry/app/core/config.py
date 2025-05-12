"""
Configuration settings for the Model Registry service.
"""
import os
from typing import List, Dict, Any, Optional
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    """
    Application settings loaded from environment variables with defaults.
    """
    # Service configuration
    SERVICE_NAME: str = "model-registry"
    DEBUG: bool = os.getenv("DEBUG", "False").lower() in ("true", "1", "t")
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    PORT: int = int(os.getenv("PORT", "8079"))
    
    # Database configuration
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL", 
        "postgresql+asyncpg://postgres:postgres@db-postgres:5432/postgres"
    )
    
    # Redis configuration
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://redis:6379/0")
    
    # Security configuration
    JWT_SECRET: str = os.getenv("JWT_SECRET", "your-super-secret-jwt-token")
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRES_MINUTES: int = 60 * 24  # 24 hours
    
    # CORS configuration
    CORS_ORIGINS: List[str] = ["*"]
    
    # Model services configuration
    OLLAMA_URL: str = os.getenv("OLLAMA_URL", "http://llm-service:11434")
    
    # OpenAI configuration
    OPENAI_API_KEY: Optional[str] = os.getenv("OPENAI_API_KEY")
    
    # Anthropic configuration
    ANTHROPIC_API_KEY: Optional[str] = os.getenv("ANTHROPIC_API_KEY")
    
    # Model discovery configuration
    DISCOVERY_INTERVAL_SECONDS: int = 300  # 5 minutes
    
    # Default model configuration
    DEFAULT_MODELS: List[Dict[str, Any]] = [
        {
            "name": "gpt4o",
            "display_name": "GPT-4o",
            "provider": "openai",
            "model_type": "chat",
            "description": "OpenAI's GPT-4o model with vision capabilities",
            "capabilities": [
                {"capability": "text", "capability_score": 0.95},
                {"capability": "image", "capability_score": 0.9},
                {"capability": "reasoning", "capability_score": 0.95}
            ]
        },
        {
            "name": "gpt4-1mini",
            "display_name": "GPT-4.1-mini",
            "provider": "openai",
            "model_type": "chat",
            "description": "OpenAI's more efficient GPT-4.1-mini model",
            "capabilities": [
                {"capability": "text", "capability_score": 0.9},
                {"capability": "reasoning", "capability_score": 0.85}
            ]
        },
        {
            "name": "gpt4-1",
            "display_name": "GPT-4.1",
            "provider": "openai",
            "model_type": "chat",
            "description": "OpenAI's GPT-4.1 for complex tasks",
            "capabilities": [
                {"capability": "text", "capability_score": 0.95},
                {"capability": "reasoning", "capability_score": 0.95},
                {"capability": "complex", "capability_score": 0.9}
            ]
        },
        {
            "name": "gpt35-turbo",
            "display_name": "GPT-3.5 Turbo",
            "provider": "openai",
            "model_type": "chat",
            "description": "OpenAI's cost-effective GPT-3.5 Turbo model",
            "capabilities": [
                {"capability": "text", "capability_score": 0.8},
                {"capability": "reasoning", "capability_score": 0.7}
            ]
        },
        {
            "name": "llama3",
            "display_name": "Llama 3 (8B)",
            "provider": "ollama",
            "model_type": "chat",
            "description": "Meta's Llama 3 model (8B version)",
            "capabilities": [
                {"capability": "text", "capability_score": 0.8},
                {"capability": "reasoning", "capability_score": 0.7}
            ]
        },
        {
            "name": "llama3:70b",
            "display_name": "Llama 3 (70B)",
            "provider": "ollama",
            "model_type": "chat",
            "description": "Meta's Llama 3 model (70B version)",
            "capabilities": [
                {"capability": "text", "capability_score": 0.9},
                {"capability": "reasoning", "capability_score": 0.85}
            ]
        },
        {
            "name": "codellama",
            "display_name": "CodeLlama",
            "provider": "ollama",
            "model_type": "chat",
            "description": "Meta's CodeLlama model for code generation and analysis",
            "capabilities": [
                {"capability": "code", "capability_score": 0.9},
                {"capability": "reasoning", "capability_score": 0.8}
            ]
        },
        {
            "name": "llava",
            "display_name": "LLaVA",
            "provider": "ollama",
            "model_type": "chat",
            "description": "Multimodal model for vision and language tasks",
            "capabilities": [
                {"capability": "text", "capability_score": 0.8},
                {"capability": "image", "capability_score": 0.8}
            ]
        },
        {
            "name": "claude-3-opus",
            "display_name": "Claude 3 Opus",
            "provider": "anthropic",
            "model_type": "chat",
            "description": "Anthropic's most powerful model for complex tasks",
            "capabilities": [
                {"capability": "text", "capability_score": 0.95},
                {"capability": "reasoning", "capability_score": 0.95},
                {"capability": "image", "capability_score": 0.9}
            ]
        },
        {
            "name": "claude-3-sonnet",
            "display_name": "Claude 3 Sonnet",
            "provider": "anthropic",
            "model_type": "chat",
            "description": "Anthropic's balanced model for general usage",
            "capabilities": [
                {"capability": "text", "capability_score": 0.9},
                {"capability": "reasoning", "capability_score": 0.85},
                {"capability": "image", "capability_score": 0.85}
            ]
        }
    ]
    
    class Config:
        """Pydantic config class."""
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

# Create global settings object
settings = Settings()