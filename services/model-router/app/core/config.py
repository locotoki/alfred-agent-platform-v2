from pydantic_settings import BaseSettings
from typing import List, Dict, Any, Optional
import os

class Settings(BaseSettings):
    # Service configuration
    SERVICE_NAME: str = "alfred-model-router"
    DEBUG: bool = os.environ.get("DEBUG", "False").lower() == "true"
    ENV: str = os.environ.get("ENV", "development")
    PORT: int = int(os.environ.get("PORT", "8080"))
    
    # Database configuration
    POSTGRES_USER: str = os.environ.get("POSTGRES_USER", "postgres")
    POSTGRES_PASSWORD: str = os.environ.get("POSTGRES_PASSWORD", "postgres")
    POSTGRES_SERVER: str = os.environ.get("POSTGRES_SERVER", "postgres")
    POSTGRES_PORT: str = os.environ.get("POSTGRES_PORT", "5432")
    POSTGRES_DB: str = os.environ.get("POSTGRES_DB", "alfred")
    DATABASE_URL: str = f"postgresql+asyncpg://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_SERVER}:{POSTGRES_PORT}/{POSTGRES_DB}"
    
    # CORS configuration
    CORS_ORIGINS: List[str] = ["*"]
    
    # JWT configuration
    JWT_SECRET: str = os.environ.get("JWT_SECRET", "alfred-model-router-secret")
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 1 week
    
    # Model Registry client configuration
    MODEL_REGISTRY_URL: str = os.environ.get("MODEL_REGISTRY_URL", "http://model-registry:8079")
    
    # Routing configuration
    DEFAULT_MODEL: str = "gpt-3.5-turbo"
    REQUEST_TIMEOUT: int = 60  # seconds
    MAX_RETRIES: int = 3
    RETRY_DELAY: int = 1  # seconds
    
    # Feature flags
    ENABLE_CAPABILITY_ROUTING: bool = True
    ENABLE_COST_OPTIMIZATION: bool = True
    ENABLE_PERFORMANCE_ROUTING: bool = True
    
    # Content type thresholds for model selection
    CONTENT_TYPE_THRESHOLDS: Dict[str, Any] = {
        "text": {
            "length_thresholds": {
                "short": 500,    # characters
                "medium": 2000,  # characters
                "long": 8000,    # characters
            }
        },
        "image": {
            "count_thresholds": {
                "few": 3,
                "many": 10,
            }
        },
        "document": {
            "page_thresholds": {
                "short": 5,
                "medium": 20,
                "long": 50,
            }
        }
    }
    
    # Fallback model configurations
    FALLBACK_MODELS: Dict[str, List[str]] = {
        "gpt-4o": ["gpt-4", "gpt-3.5-turbo"],
        "gpt-4": ["gpt-3.5-turbo"],
        "llama3-70b": ["llama3-8b", "gpt-3.5-turbo"],
        "claude-3-opus": ["claude-3-sonnet", "gpt-3.5-turbo"],
    }
    
    # Model selection rules
    # These rules define how models are selected based on request characteristics
    SELECTION_RULES: Dict[str, Dict[str, Any]] = {
        "default": {
            "model": "gpt-3.5-turbo",
            "priority": 1,
        },
        "premium_tier": {
            "model": "gpt-4o",
            "priority": 10,
            "conditions": {
                "user_tier": ["premium", "enterprise"],
            },
        },
        "image_processing": {
            "model": "gpt-4o",
            "priority": 20,
            "conditions": {
                "content_type": ["image"],
                "content_count": {"min": 1},
            },
        },
        "document_processing": {
            "model": "claude-3-opus",
            "priority": 25,
            "conditions": {
                "content_type": ["document"],
                "page_count": {"min": 10},
            },
        },
        "long_context": {
            "model": "claude-3-opus",
            "priority": 30,
            "conditions": {
                "content_type": ["text"],
                "token_count": {"min": 8000},
            },
        },
        "code_generation": {
            "model": "gpt-4o",
            "priority": 35,
            "conditions": {
                "task_type": ["code_generation", "code_explanation"],
            },
        },
        "local_inference": {
            "model": "llama3-70b",
            "priority": 40,
            "conditions": {
                "require_local_inference": True,
            },
        },
    }
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True

# Create global settings instance
settings = Settings()