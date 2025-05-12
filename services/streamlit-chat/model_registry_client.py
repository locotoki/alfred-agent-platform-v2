import requests
import json
from typing import List, Dict, Any, Optional
import os
import logging
from datetime import datetime
import time

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ModelRegistryClient:
    """Client for interacting with the Model Registry service."""
    
    def __init__(self, base_url: Optional[str] = None):
        """Initialize the Model Registry client."""
        self.base_url = base_url or os.environ.get("MODEL_REGISTRY_URL", "http://model-registry:8079")
        self._models_cache = {}
        self._last_refresh = 0
        self._cache_ttl = 60  # Cache TTL in seconds
        
    def _refresh_cache_if_needed(self):
        """Refresh the models cache if it's expired."""
        current_time = time.time()
        if current_time - self._last_refresh > self._cache_ttl:
            self.refresh_models_cache()
    
    def refresh_models_cache(self):
        """Refresh the models cache."""
        try:
            models = self.get_all_models()
            self._models_cache = {model["name"]: model for model in models}
            self._last_refresh = time.time()
            logger.info(f"Refreshed models cache. Found {len(models)} models.")
        except Exception as e:
            logger.error(f"Failed to refresh models cache: {e}")
    
    def get_all_models(self) -> List[Dict[str, Any]]:
        """
        Get all available models from the Model Registry.

        Returns:
            List of model configurations
        """
        try:
            response = requests.get(f"{self.base_url}/api/v1/models", timeout=2)
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Error fetching models: {e}")
            # If connection fails, return hardcoded models from config
            if not self._models_cache:
                # Hardcoded models when Model Registry is unavailable
                return [
                    {
                        "name": "gpt4o",
                        "display_name": "GPT-4o",
                        "provider": "openai",
                        "description": "OpenAI's GPT-4o model with vision capabilities",
                        "active": True
                    },
                    {
                        "name": "gpt4-1mini",
                        "display_name": "GPT-4.1-mini",
                        "provider": "openai",
                        "description": "OpenAI's more efficient GPT-4.1-mini model",
                        "active": True
                    },
                    {
                        "name": "gpt4-1",
                        "display_name": "GPT-4.1",
                        "provider": "openai",
                        "description": "OpenAI's GPT-4.1 for complex tasks",
                        "active": True
                    },
                    {
                        "name": "gpt35-turbo",
                        "display_name": "GPT-3.5 Turbo",
                        "provider": "openai",
                        "description": "OpenAI's cost-effective GPT-3.5 Turbo model",
                        "active": True
                    },
                    {
                        "name": "llama3",
                        "display_name": "Llama 3 (8B)",
                        "provider": "ollama",
                        "description": "Meta's Llama 3 model (8B version)",
                        "active": True
                    },
                    {
                        "name": "llama3:70b",
                        "display_name": "Llama 3 (70B)",
                        "provider": "ollama",
                        "description": "Meta's Llama 3 model (70B version)",
                        "active": True
                    },
                    {
                        "name": "codellama",
                        "display_name": "CodeLlama",
                        "provider": "ollama",
                        "description": "Meta's CodeLlama model for code generation and analysis",
                        "active": True
                    },
                    {
                        "name": "llava",
                        "display_name": "LLaVA",
                        "provider": "ollama",
                        "description": "Multimodal model for vision and language tasks",
                        "active": True
                    }
                ]

            # Return cached data if available
            return list(self._models_cache.values()) if self._models_cache else []
    
    def get_model_by_name(self, name: str) -> Optional[Dict[str, Any]]:
        """
        Get a specific model by name.

        Args:
            name: The name of the model to retrieve

        Returns:
            Model configuration if found, None otherwise
        """
        self._refresh_cache_if_needed()

        # Check cache first
        if name in self._models_cache:
            return self._models_cache[name]

        # Special handling for 'auto'
        if name == 'auto':
            return {
                "name": "auto",
                "display_name": "Auto (Let system decide)",
                "provider": "system",
                "description": "Automatically select the best model based on your query",
                "active": True
            }

        # Try direct API call if not in cache
        try:
            response = requests.get(f"{self.base_url}/api/v1/models/{name}", timeout=2)
            if response.status_code == 200:
                model = response.json()
                self._models_cache[name] = model
                return model

            # Check hardcoded models if API fails
            all_models = self.get_all_models()
            for model in all_models:
                if model["name"] == name:
                    return model

            return None
        except requests.RequestException as e:
            logger.error(f"Error fetching model {name}: {e}")

            # Check hardcoded models if API fails
            all_models = self.get_all_models()
            for model in all_models:
                if model["name"] == name:
                    return model

            return None
    
    def get_models_by_provider(self, provider: str) -> List[Dict[str, Any]]:
        """
        Get models from a specific provider.
        
        Args:
            provider: The provider to filter by (e.g., 'openai', 'ollama')
            
        Returns:
            List of model configurations matching the provider
        """
        self._refresh_cache_if_needed()
        
        # Filter models by provider from cache if available
        if self._models_cache:
            return [model for model in self._models_cache.values() if model.get("provider") == provider]
        
        # Otherwise fetch all and filter
        all_models = self.get_all_models()
        return [model for model in all_models if model.get("provider") == provider]
    
    def get_models_by_capability(self, capability: str) -> List[Dict[str, Any]]:
        """
        Get models that support a specific capability.
        
        Args:
            capability: The capability to filter by (e.g., 'text', 'image')
            
        Returns:
            List of model configurations supporting the capability
        """
        try:
            response = requests.get(f"{self.base_url}/api/v1/models/capability/{capability}")
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Error fetching models with capability {capability}: {e}")
            # Fall back to filtering from all models
            all_models = list(self._models_cache.values()) if self._models_cache else self.get_all_models()
            return [
                model for model in all_models 
                if any(cap.get("capability") == capability for cap in model.get("capabilities", []))
            ]