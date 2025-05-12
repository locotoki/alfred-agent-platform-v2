import aiohttp
import logging
import time
import json
from typing import Dict, List, Any, Optional
import asyncio
from fastapi import HTTPException

from app.core.config import settings

logger = logging.getLogger(__name__)

class RegistryClient:
    """Client for interacting with the Model Registry service"""
    
    def __init__(self, base_url: str):
        """Initialize the Model Registry client with base URL"""
        self.base_url = base_url
        self.session = None
        self.models_cache = {}
        self.capabilities_cache = {}
        self.last_cache_update = 0
        self.cache_ttl = 60  # Cache TTL in seconds
        self.lock = asyncio.Lock()
        
    async def initialize(self):
        """Initialize the HTTP session"""
        if self.session is None:
            self.session = aiohttp.ClientSession()
            await self.refresh_cache()
        
    async def close(self):
        """Close the HTTP session"""
        if self.session:
            await self.session.close()
            self.session = None
            
    async def refresh_cache(self):
        """Refresh the models and capabilities cache"""
        async with self.lock:
            if time.time() - self.last_cache_update < self.cache_ttl:
                return
                
            try:
                # Get all models
                models = await self.get_models()
                self.models_cache = {model["id"]: model for model in models}
                
                # Get capabilities for each model
                for model_id, model in self.models_cache.items():
                    capabilities = await self.get_model_capabilities(model_id)
                    self.capabilities_cache[model_id] = capabilities
                    
                self.last_cache_update = time.time()
                logger.info(f"Refreshed model registry cache: {len(self.models_cache)} models")
            except Exception as e:
                logger.error(f"Failed to refresh model registry cache: {e}")
                # Don't update last_cache_update to force retry on next request
    
    async def get_models(self) -> List[Dict[str, Any]]:
        """Get all models from the registry"""
        if not self.session:
            await self.initialize()
            
        try:
            async with self.session.get(f"{self.base_url}/api/v1/models") as response:
                if response.status == 200:
                    return await response.json()
                else:
                    error_text = await response.text()
                    logger.error(f"Failed to get models: {error_text}")
                    raise HTTPException(status_code=response.status, detail=f"Model Registry error: {error_text}")
        except aiohttp.ClientError as e:
            logger.error(f"Client error when getting models: {e}")
            raise HTTPException(status_code=503, detail=f"Model Registry service unavailable: {e}")
    
    async def get_model(self, model_id: str) -> Dict[str, Any]:
        """Get a specific model from the registry"""
        # Check cache first
        current_time = time.time()
        if model_id in self.models_cache and current_time - self.last_cache_update < self.cache_ttl:
            return self.models_cache[model_id]
            
        # If not in cache or cache expired, fetch from registry
        if not self.session:
            await self.initialize()
            
        try:
            async with self.session.get(f"{self.base_url}/api/v1/models/{model_id}") as response:
                if response.status == 200:
                    model = await response.json()
                    # Update cache
                    self.models_cache[model_id] = model
                    return model
                else:
                    error_text = await response.text()
                    logger.error(f"Failed to get model {model_id}: {error_text}")
                    raise HTTPException(status_code=response.status, detail=f"Model Registry error: {error_text}")
        except aiohttp.ClientError as e:
            logger.error(f"Client error when getting model {model_id}: {e}")
            raise HTTPException(status_code=503, detail=f"Model Registry service unavailable: {e}")
    
    async def get_model_capabilities(self, model_id: str) -> Dict[str, Any]:
        """Get capabilities for a specific model"""
        # Check cache first
        current_time = time.time()
        if model_id in self.capabilities_cache and current_time - self.last_cache_update < self.cache_ttl:
            return self.capabilities_cache[model_id]
            
        # If not in cache or cache expired, fetch from registry
        if not self.session:
            await self.initialize()
            
        try:
            async with self.session.get(f"{self.base_url}/api/v1/models/{model_id}/capabilities") as response:
                if response.status == 200:
                    capabilities = await response.json()
                    # Update cache
                    self.capabilities_cache[model_id] = capabilities
                    return capabilities
                else:
                    error_text = await response.text()
                    logger.error(f"Failed to get capabilities for model {model_id}: {error_text}")
                    raise HTTPException(status_code=response.status, detail=f"Model Registry error: {error_text}")
        except aiohttp.ClientError as e:
            logger.error(f"Client error when getting capabilities for model {model_id}: {e}")
            raise HTTPException(status_code=503, detail=f"Model Registry service unavailable: {e}")
    
    async def get_models_by_capability(self, capability: str, value: bool = True) -> List[Dict[str, Any]]:
        """Get models that have a specific capability"""
        await self.refresh_cache()
        
        models_with_capability = []
        for model_id, capabilities in self.capabilities_cache.items():
            if capability in capabilities and capabilities[capability] == value:
                models_with_capability.append(self.models_cache[model_id])
                
        return models_with_capability
    
    async def get_models_by_task(self, task_type: str) -> List[Dict[str, Any]]:
        """Get models that support a specific task type"""
        await self.refresh_cache()
        
        models_for_task = []
        for model_id, capabilities in self.capabilities_cache.items():
            if "task_types" in capabilities and task_type in capabilities["task_types"]:
                models_for_task.append(self.models_cache[model_id])
                
        return models_for_task
    
    async def get_models_by_content_type(self, content_type: str) -> List[Dict[str, Any]]:
        """Get models that support a specific content type"""
        await self.refresh_cache()
        
        models_for_content = []
        for model_id, capabilities in self.capabilities_cache.items():
            if "content_types" in capabilities and content_type in capabilities["content_types"]:
                models_for_content.append(self.models_cache[model_id])
                
        return models_for_content
    
    async def log_model_usage(self, model_id: str, usage_data: Dict[str, Any]) -> Dict[str, Any]:
        """Log model usage metrics"""
        if not self.session:
            await self.initialize()
            
        try:
            async with self.session.post(
                f"{self.base_url}/api/v1/models/{model_id}/usage",
                json=usage_data
            ) as response:
                if response.status == 200:
                    return await response.json()
                else:
                    error_text = await response.text()
                    logger.error(f"Failed to log usage for model {model_id}: {error_text}")
                    # Don't raise exception for logging failures
                    return {"success": False, "error": error_text}
        except aiohttp.ClientError as e:
            logger.error(f"Client error when logging usage for model {model_id}: {e}")
            return {"success": False, "error": str(e)}