"""
Model discovery service for automatically discovering and registering models.
"""
import asyncio
import json
import time
from typing import List, Dict, Any, Optional
import httpx
import structlog
from tenacity import retry, stop_after_attempt, wait_exponential
from sqlalchemy import text

from app.core.config import settings
from app.models.models import Model, ModelCapability, ModelParameter, ModelEndpoint
from app.services.database import async_session_factory

# Configure logging
logger = structlog.get_logger(__name__)

class ModelDiscoveryService:
    """
    Service for discovering available models from different providers.
    """
    def __init__(self):
        """Initialize the discovery service."""
        self.http_client = httpx.AsyncClient(timeout=30.0)
        self.ollama_url = settings.OLLAMA_URL
        self.openai_api_key = settings.OPENAI_API_KEY
        self.anthropic_api_key = settings.ANTHROPIC_API_KEY
        self.discovery_task = None
        self.discovery_interval = settings.DISCOVERY_INTERVAL_SECONDS
        self.default_models = settings.DEFAULT_MODELS
    
    async def initialize(self):
        """Initialize the discovery service."""
        logger.info("Initializing model discovery service")
        
        # Register default models
        await self.register_default_models()
        
    async def register_default_models(self):
        """Register default models from configuration."""
        logger.info("Registering default models", count=len(self.default_models))
        
        async with async_session_factory() as session:
            for model_data in self.default_models:
                # Check if model already exists
                model_query = await session.execute(
                    text("SELECT id FROM model_registry.models WHERE name = :name"),
                    {"name": model_data["name"]}
                )
                model_result = model_query.first()
                
                if model_result:
                    # Model exists, update it
                    model_id = model_result[0]
                    await session.execute(
                        text("""
                        UPDATE model_registry.models 
                        SET 
                            display_name = :display_name,
                            provider = :provider,
                            model_type = :model_type,
                            description = :description,
                            updated_at = NOW()
                        WHERE id = :model_id
                        """),
                        {
                            "model_id": model_id,
                            "display_name": model_data["display_name"],
                            "provider": model_data["provider"],
                            "model_type": model_data["model_type"],
                            "description": model_data.get("description", "")
                        }
                    )
                    
                    # Update capabilities
                    if "capabilities" in model_data:
                        # Delete existing capabilities
                        await session.execute(
                            text("DELETE FROM model_registry.model_capabilities WHERE model_id = :model_id"),
                            {"model_id": model_id}
                        )
                        
                        # Insert new capabilities
                        for capability in model_data["capabilities"]:
                            await session.execute(
                                text("""
                                INSERT INTO model_registry.model_capabilities
                                (model_id, capability, capability_score)
                                VALUES (:model_id, :capability, :capability_score)
                                """),
                                {
                                    "model_id": model_id,
                                    "capability": capability["capability"],
                                    "capability_score": capability["capability_score"]
                                }
                            )
                else:
                    # Create new model
                    model_insert = await session.execute(
                        text("""
                        INSERT INTO model_registry.models
                        (name, display_name, provider, model_type, description, created_at, updated_at)
                        VALUES (:name, :display_name, :provider, :model_type, :description, NOW(), NOW())
                        RETURNING id
                        """),
                        {
                            "name": model_data["name"],
                            "display_name": model_data["display_name"],
                            "provider": model_data["provider"],
                            "model_type": model_data["model_type"],
                            "description": model_data.get("description", "")
                        }
                    )
                    model_id = model_insert.first()[0]
                    
                    # Insert capabilities
                    if "capabilities" in model_data:
                        for capability in model_data["capabilities"]:
                            await session.execute(
                                text("""
                                INSERT INTO model_registry.model_capabilities
                                (model_id, capability, capability_score)
                                VALUES (:model_id, :capability, :capability_score)
                                """),
                                {
                                    "model_id": model_id,
                                    "capability": capability["capability"],
                                    "capability_score": capability["capability_score"]
                                }
                            )
            
            # Commit all changes
            await session.commit()
        
        logger.info("Default models registered successfully")
    
    async def start_background_discovery(self):
        """Start the background discovery task."""
        if self.discovery_task is None or self.discovery_task.done():
            self.discovery_task = asyncio.create_task(self._discovery_loop())
            logger.info("Started background model discovery task")
    
    async def _discovery_loop(self):
        """Background task loop for model discovery."""
        while True:
            try:
                # Discover models from various providers
                await self.discover_models()
                
                # Wait for the next discovery interval
                await asyncio.sleep(self.discovery_interval)
            except asyncio.CancelledError:
                logger.info("Model discovery task cancelled")
                break
            except Exception as e:
                logger.error("Error in model discovery loop", error=str(e))
                # Wait before retrying
                await asyncio.sleep(60)
    
    async def discover_models(self):
        """Discover models from all configured providers."""
        logger.info("Starting model discovery cycle")
        start_time = time.time()
        
        # Discover from different providers
        tasks = []
        
        # Ollama models
        tasks.append(self.discover_ollama_models())
        
        # OpenAI models (if API key is configured)
        if self.openai_api_key:
            tasks.append(self.discover_openai_models())
        
        # Anthropic models (if API key is configured)
        if self.anthropic_api_key:
            tasks.append(self.discover_anthropic_models())
        
        # Wait for all discovery tasks to complete
        discovery_results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Process results
        total_models = 0
        for result in discovery_results:
            if isinstance(result, Exception):
                logger.error("Error during model discovery", error=str(result))
            elif isinstance(result, int):
                total_models += result
        
        duration = time.time() - start_time
        logger.info(
            "Model discovery cycle completed", 
            total_models=total_models,
            duration_seconds=round(duration, 2)
        )
    
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=10))
    async def discover_ollama_models(self) -> int:
        """
        Discover models available in Ollama.
        Returns the number of models found.
        """
        logger.info("Discovering Ollama models", url=self.ollama_url)
        
        try:
            # Get list of models from Ollama
            async with self.http_client.stream("GET", f"{self.ollama_url}/api/tags") as response:
                if response.status_code != 200:
                    logger.error(
                        "Failed to get Ollama models",
                        status_code=response.status_code,
                        response=await response.text()
                    )
                    return 0
                
                data = await response.json()
                models = data.get("models", [])
                
                # Register discovered models
                count = await self._register_ollama_models(models)
                logger.info("Ollama model discovery completed", count=count)
                return count
        except Exception as e:
            logger.error("Error discovering Ollama models", error=str(e))
            raise
    
    async def _register_ollama_models(self, models: List[Dict[str, Any]]) -> int:
        """Register discovered Ollama models in the database."""
        if not models:
            return 0
        
        count = 0
        async with async_session_factory() as session:
            for model in models:
                model_name = model.get("name", "")
                if not model_name:
                    continue
                
                # Check if model already exists
                model_query = await session.execute(
                    text("SELECT id FROM model_registry.models WHERE name = :name"),
                    {"name": model_name}
                )
                model_result = model_query.first()
                
                # Extract model metadata
                model_size = model.get("size", 0)
                model_modified = model.get("modified", "")
                
                # Determine display name (remove tag if present)
                display_name = model_name
                if ":" in model_name:
                    base_name, tag = model_name.split(":", 1)
                    display_name = f"{base_name.capitalize()} ({tag})"
                else:
                    display_name = model_name.capitalize()
                
                if model_result:
                    # Model exists, update it
                    model_id = model_result[0]
                    await session.execute(
                        text("""
                        UPDATE model_registry.models 
                        SET 
                            display_name = :display_name,
                            provider = 'ollama',
                            model_type = 'chat',
                            description = :description,
                            updated_at = NOW()
                        WHERE id = :model_id
                        """),
                        {
                            "model_id": model_id,
                            "display_name": display_name,
                            "description": f"Ollama model {display_name} ({model_size} bytes, modified {model_modified})"
                        }
                    )
                else:
                    # Create new model
                    model_insert = await session.execute(
                        text("""
                        INSERT INTO model_registry.models
                        (name, display_name, provider, model_type, description, created_at, updated_at)
                        VALUES (:name, :display_name, 'ollama', 'chat', :description, NOW(), NOW())
                        RETURNING id
                        """),
                        {
                            "name": model_name,
                            "display_name": display_name,
                            "description": f"Ollama model {display_name} ({model_size} bytes, modified {model_modified})"
                        }
                    )
                    model_id = model_insert.first()[0]
                    
                    # Insert default capabilities based on model name
                    capabilities = []
                    
                    # Add text capability for all models
                    capabilities.append(("text", 0.8))
                    
                    # Add specialized capabilities based on model name
                    if "code" in model_name.lower() or "llama-2" in model_name.lower():
                        capabilities.append(("code", 0.8))
                    
                    if "llava" in model_name.lower() or "bakllava" in model_name.lower():
                        capabilities.append(("image", 0.8))
                    
                    if "instruct" in model_name.lower() or "chat" in model_name.lower():
                        capabilities.append(("reasoning", 0.7))
                    
                    # Insert capabilities
                    for capability, score in capabilities:
                        await session.execute(
                            text("""
                            INSERT INTO model_registry.model_capabilities
                            (model_id, capability, capability_score)
                            VALUES (:model_id, :capability, :capability_score)
                            """),
                            {
                                "model_id": model_id,
                                "capability": capability,
                                "capability_score": score
                            }
                        )
                    
                    # Insert endpoint
                    await session.execute(
                        text("""
                        INSERT INTO model_registry.model_endpoints
                        (model_id, endpoint_type, endpoint_url, auth_type, created_at, updated_at)
                        VALUES (:model_id, 'rest', :endpoint_url, 'none', NOW(), NOW())
                        """),
                        {
                            "model_id": model_id,
                            "endpoint_url": f"{self.ollama_url}/api/generate"
                        }
                    )
                    
                    # Insert default parameters
                    parameters = [
                        ("temperature", {"value": 0.7}, {"value": 0.0}, {"value": 1.0}, "Controls randomness in generation"),
                        ("top_p", {"value": 0.95}, {"value": 0.0}, {"value": 1.0}, "Controls diversity in generation"),
                        ("top_k", {"value": 40}, {"value": 1}, {"value": 100}, "Limits vocabulary to top K tokens"),
                        ("max_tokens", {"value": 2048}, {"value": 1}, {"value": 4096}, "Maximum tokens to generate")
                    ]
                    
                    for name, default, min_val, max_val, desc in parameters:
                        await session.execute(
                            text("""
                            INSERT INTO model_registry.model_parameters
                            (model_id, parameter_name, default_value, min_value, max_value, description)
                            VALUES (:model_id, :name, :default, :min, :max, :desc)
                            """),
                            {
                                "model_id": model_id,
                                "name": name,
                                "default": json.dumps(default),
                                "min": json.dumps(min_val),
                                "max": json.dumps(max_val),
                                "desc": desc
                            }
                        )
                
                count += 1
            
            # Commit all changes
            await session.commit()
        
        return count
    
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=10))
    async def discover_openai_models(self) -> int:
        """
        Discover models available from OpenAI.
        Returns the number of models found.
        """
        logger.info("Discovering OpenAI models")
        
        # Check if API key is configured
        if not self.openai_api_key:
            logger.warning("OpenAI API key not configured, skipping discovery")
            return 0
        
        try:
            # Get list of models from OpenAI
            headers = {
                "Authorization": f"Bearer {self.openai_api_key}",
                "Content-Type": "application/json"
            }
            
            async with self.http_client.stream("GET", "https://api.openai.com/v1/models", headers=headers) as response:
                if response.status_code != 200:
                    logger.error(
                        "Failed to get OpenAI models",
                        status_code=response.status_code,
                        response=await response.text()
                    )
                    return 0
                
                data = await response.json()
                models = data.get("data", [])
                
                # Register discovered models
                count = await self._register_openai_models(models)
                logger.info("OpenAI model discovery completed", count=count)
                return count
        except Exception as e:
            logger.error("Error discovering OpenAI models", error=str(e))
            raise
    
    async def _register_openai_models(self, models: List[Dict[str, Any]]) -> int:
        """Register discovered OpenAI models in the database."""
        if not models:
            return 0
        
        # Filter to only include models we want to register
        target_models = ["gpt-4o", "gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"]
        filtered_models = [
            model for model in models 
            if any(target in model.get("id", "") for target in target_models)
        ]
        
        count = 0
        async with async_session_factory() as session:
            for model in filtered_models:
                model_id = model.get("id", "")
                if not model_id:
                    continue
                
                # Clean up model ID to use as name
                model_name = model_id.replace(".", "").replace("-", "")
                
                # Determine display name
                display_name = model_id
                
                # Get model details
                owned_by = model.get("owned_by", "openai")
                
                # Check if model already exists
                model_query = await session.execute(
                    text("SELECT id FROM model_registry.models WHERE name = :name"),
                    {"name": model_name}
                )
                model_result = model_query.first()
                
                if model_result:
                    # Model exists, update it
                    model_id_db = model_result[0]
                    await session.execute(
                        text("""
                        UPDATE model_registry.models 
                        SET 
                            display_name = :display_name,
                            provider = 'openai',
                            model_type = 'chat',
                            description = :description,
                            updated_at = NOW()
                        WHERE id = :model_id
                        """),
                        {
                            "model_id": model_id_db,
                            "display_name": display_name,
                            "description": f"OpenAI model {display_name} (owned by {owned_by})"
                        }
                    )
                else:
                    # Create new model
                    model_insert = await session.execute(
                        text("""
                        INSERT INTO model_registry.models
                        (name, display_name, provider, model_type, description, created_at, updated_at)
                        VALUES (:name, :display_name, 'openai', 'chat', :description, NOW(), NOW())
                        RETURNING id
                        """),
                        {
                            "name": model_name,
                            "display_name": display_name,
                            "description": f"OpenAI model {display_name} (owned by {owned_by})"
                        }
                    )
                    model_id_db = model_insert.first()[0]
                    
                    # Insert default capabilities based on model name
                    capabilities = []
                    
                    # Add text capability for all models
                    capabilities.append(("text", 0.9))
                    
                    # Add specialized capabilities based on model name
                    if "gpt4" in model_name.lower():
                        capabilities.append(("reasoning", 0.95))
                        
                    if "o" in model_name.lower():
                        capabilities.append(("image", 0.9))
                    
                    # Insert capabilities
                    for capability, score in capabilities:
                        await session.execute(
                            text("""
                            INSERT INTO model_registry.model_capabilities
                            (model_id, capability, capability_score)
                            VALUES (:model_id, :capability, :capability_score)
                            """),
                            {
                                "model_id": model_id_db,
                                "capability": capability,
                                "capability_score": score
                            }
                        )
                    
                    # Insert endpoint
                    await session.execute(
                        text("""
                        INSERT INTO model_registry.model_endpoints
                        (model_id, endpoint_type, endpoint_url, auth_type, created_at, updated_at)
                        VALUES (:model_id, 'rest', :endpoint_url, 'api_key', NOW(), NOW())
                        """),
                        {
                            "model_id": model_id_db,
                            "endpoint_url": "https://api.openai.com/v1/chat/completions"
                        }
                    )
                    
                    # Insert default parameters
                    parameters = [
                        ("temperature", {"value": 0.7}, {"value": 0.0}, {"value": 2.0}, "Controls randomness in generation"),
                        ("top_p", {"value": 0.95}, {"value": 0.0}, {"value": 1.0}, "Controls diversity in generation"),
                        ("max_tokens", {"value": 1024}, {"value": 1}, {"value": 4096}, "Maximum tokens to generate"),
                        ("presence_penalty", {"value": 0.0}, {"value": -2.0}, {"value": 2.0}, "Penalizes repeated tokens"),
                        ("frequency_penalty", {"value": 0.0}, {"value": -2.0}, {"value": 2.0}, "Penalizes frequent tokens")
                    ]
                    
                    for name, default, min_val, max_val, desc in parameters:
                        await session.execute(
                            text("""
                            INSERT INTO model_registry.model_parameters
                            (model_id, parameter_name, default_value, min_value, max_value, description)
                            VALUES (:model_id, :name, :default, :min, :max, :desc)
                            """),
                            {
                                "model_id": model_id_db,
                                "name": name,
                                "default": json.dumps(default),
                                "min": json.dumps(min_val),
                                "max": json.dumps(max_val),
                                "desc": desc
                            }
                        )
                
                count += 1
            
            # Commit all changes
            await session.commit()
        
        return count
    
    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=10))
    async def discover_anthropic_models(self) -> int:
        """
        Discover models available from Anthropic.
        Returns the number of models found.
        """
        logger.info("Discovering Anthropic models")
        
        # Check if API key is configured
        if not self.anthropic_api_key:
            logger.warning("Anthropic API key not configured, skipping discovery")
            return 0
        
        # Anthropic doesn't have a models list endpoint, so we'll register known models
        try:
            # Define known Anthropic models
            anthropic_models = [
                {
                    "id": "claude-3-opus",
                    "name": "claude3opus",
                    "display_name": "Claude 3 Opus",
                    "description": "Anthropic's most powerful model for highly complex tasks"
                },
                {
                    "id": "claude-3-sonnet",
                    "name": "claude3sonnet",
                    "display_name": "Claude 3 Sonnet",
                    "description": "Anthropic's balanced model for enterprise workloads"
                },
                {
                    "id": "claude-3-haiku",
                    "name": "claude3haiku",
                    "display_name": "Claude 3 Haiku",
                    "description": "Anthropic's fastest and most compact model"
                }
            ]
            
            # Register discovered models
            count = await self._register_anthropic_models(anthropic_models)
            logger.info("Anthropic model discovery completed", count=count)
            return count
        except Exception as e:
            logger.error("Error discovering Anthropic models", error=str(e))
            raise
    
    async def _register_anthropic_models(self, models: List[Dict[str, Any]]) -> int:
        """Register Anthropic models in the database."""
        if not models:
            return 0
        
        count = 0
        async with async_session_factory() as session:
            for model in models:
                model_id = model.get("id", "")
                model_name = model.get("name", "")
                display_name = model.get("display_name", "")
                description = model.get("description", "")
                
                if not model_id or not model_name:
                    continue
                
                # Check if model already exists
                model_query = await session.execute(
                    text("SELECT id FROM model_registry.models WHERE name = :name"),
                    {"name": model_name}
                )
                model_result = model_query.first()
                
                if model_result:
                    # Model exists, update it
                    model_id_db = model_result[0]
                    await session.execute(
                        text("""
                        UPDATE model_registry.models 
                        SET 
                            display_name = :display_name,
                            provider = 'anthropic',
                            model_type = 'chat',
                            description = :description,
                            updated_at = NOW()
                        WHERE id = :model_id
                        """),
                        {
                            "model_id": model_id_db,
                            "display_name": display_name,
                            "description": description
                        }
                    )
                else:
                    # Create new model
                    model_insert = await session.execute(
                        text("""
                        INSERT INTO model_registry.models
                        (name, display_name, provider, model_type, description, created_at, updated_at)
                        VALUES (:name, :display_name, 'anthropic', 'chat', :description, NOW(), NOW())
                        RETURNING id
                        """),
                        {
                            "name": model_name,
                            "display_name": display_name,
                            "description": description
                        }
                    )
                    model_id_db = model_insert.first()[0]
                    
                    # Insert capabilities
                    capabilities = [
                        ("text", 0.95),
                        ("reasoning", 0.9),
                    ]
                    
                    # Add image capability for Claude 3
                    if "claude-3" in model_id:
                        capabilities.append(("image", 0.85))
                    
                    # Insert capabilities
                    for capability, score in capabilities:
                        await session.execute(
                            text("""
                            INSERT INTO model_registry.model_capabilities
                            (model_id, capability, capability_score)
                            VALUES (:model_id, :capability, :capability_score)
                            """),
                            {
                                "model_id": model_id_db,
                                "capability": capability,
                                "capability_score": score
                            }
                        )
                    
                    # Insert endpoint
                    await session.execute(
                        text("""
                        INSERT INTO model_registry.model_endpoints
                        (model_id, endpoint_type, endpoint_url, auth_type, created_at, updated_at)
                        VALUES (:model_id, 'rest', :endpoint_url, 'api_key', NOW(), NOW())
                        """),
                        {
                            "model_id": model_id_db,
                            "endpoint_url": "https://api.anthropic.com/v1/messages"
                        }
                    )
                    
                    # Insert default parameters
                    parameters = [
                        ("temperature", {"value": 0.7}, {"value": 0.0}, {"value": 1.0}, "Controls randomness in generation"),
                        ("max_tokens", {"value": 1024}, {"value": 1}, {"value": 4096}, "Maximum tokens to generate"),
                        ("top_p", {"value": 0.95}, {"value": 0.0}, {"value": 1.0}, "Controls diversity in generation")
                    ]
                    
                    for name, default, min_val, max_val, desc in parameters:
                        await session.execute(
                            text("""
                            INSERT INTO model_registry.model_parameters
                            (model_id, parameter_name, default_value, min_value, max_value, description)
                            VALUES (:model_id, :name, :default, :min, :max, :desc)
                            """),
                            {
                                "model_id": model_id_db,
                                "name": name,
                                "default": json.dumps(default),
                                "min": json.dumps(min_val),
                                "max": json.dumps(max_val),
                                "desc": desc
                            }
                        )
                
                count += 1
            
            # Commit all changes
            await session.commit()
        
        return count
    
    async def cleanup(self):
        """Cleanup resources used by the discovery service."""
        # Cancel the discovery task if running
        if self.discovery_task is not None and not self.discovery_task.done():
            self.discovery_task.cancel()
            try:
                await self.discovery_task
            except asyncio.CancelledError:
                pass
        
        # Close the HTTP client
        await self.http_client.aclose()