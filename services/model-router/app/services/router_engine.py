import logging
from typing import Dict, List, Any, Tuple, Optional
import re
import tiktoken
import json
import time
import asyncio
import uuid
from datetime import datetime

from app.core.config import settings
from app.models.models import (
    RoutingRequest, 
    RoutingResponse, 
    RoutingMetrics,
    ContentType,
    TaskType,
    UserTier,
    SelectionRule,
    RuleCondition
)
from app.services.registry_client import RegistryClient

logger = logging.getLogger(__name__)

class RouterEngine:
    """Engine for routing requests to the most appropriate model"""
    
    def __init__(self, registry_client: RegistryClient):
        """Initialize the router engine with a registry client"""
        self.registry_client = registry_client
        self.rules = []
        self.tokenizer = None
        try:
            self.tokenizer = tiktoken.get_encoding("cl100k_base")
        except Exception as e:
            logger.warning(f"Failed to load tiktoken tokenizer: {e}. Token counting will be less accurate.")
        
    async def initialize(self):
        """Initialize the router engine"""
        # Load selection rules from settings
        self.rules = self._load_selection_rules()
        logger.info(f"Initialized router engine with {len(self.rules)} selection rules")
        
    def _load_selection_rules(self) -> List[SelectionRule]:
        """Load selection rules from settings"""
        rules = []
        
        # Convert settings rules to SelectionRule objects
        for rule_id, rule_config in settings.SELECTION_RULES.items():
            # Extract conditions from rule config
            conditions_dict = rule_config.get("conditions", {})
            
            # Create RuleCondition object
            conditions = RuleCondition(
                content_type=conditions_dict.get("content_type"),
                task_type=conditions_dict.get("task_type"),
                user_tier=conditions_dict.get("user_tier"),
                token_count=conditions_dict.get("token_count"),
                content_count=conditions_dict.get("content_count"),
                page_count=conditions_dict.get("page_count"),
                require_local_inference=conditions_dict.get("require_local_inference"),
                require_stream=conditions_dict.get("require_stream"),
                require_gpu=conditions_dict.get("require_gpu"),
                tags=conditions_dict.get("tags")
            )
            
            # Create SelectionRule object
            rule = SelectionRule(
                id=rule_id,
                name=rule_id.replace("_", " ").title(),
                description=rule_config.get("description"),
                model=rule_config.get("model"),
                priority=rule_config.get("priority", 0),
                conditions=conditions,
                fallback_models=settings.FALLBACK_MODELS.get(rule_config.get("model"), []),
                active=True
            )
            
            rules.append(rule)
            
        # Sort rules by priority (highest first)
        rules.sort(key=lambda r: r.priority, reverse=True)
        return rules
    
    def _estimate_token_count(self, text: str) -> int:
        """Estimate token count for a text string"""
        if self.tokenizer:
            return len(self.tokenizer.encode(text))
        else:
            # Fallback estimation: ~4 characters per token
            return len(text) // 4
            
    def _analyze_request_content(self, request: RoutingRequest) -> Dict[str, Any]:
        """Analyze request content to extract characteristics"""
        analysis = {
            "content_types": [],
            "token_count": 0,
            "text_length": 0,
            "image_count": 0,
            "document_count": 0,
            "document_pages": 0,
            "code_count": 0,
            "code_lines": 0,
            "has_json": False,
            "has_html": False,
            "has_xml": False,
            "has_csv": False,
            "has_pdf": False,
        }
        
        # Process each content item
        for item in request.content:
            # Track content type
            if item.type not in analysis["content_types"]:
                analysis["content_types"].append(item.type)
                
            # Process based on content type
            if item.type == ContentType.TEXT:
                text_content = item.content
                analysis["text_length"] += len(text_content)
                analysis["token_count"] += self._estimate_token_count(text_content)
                
            elif item.type == ContentType.IMAGE:
                analysis["image_count"] += 1
                
            elif item.type == ContentType.DOCUMENT:
                analysis["document_count"] += 1
                # Get page count from metadata if available
                if item.metadata and "page_count" in item.metadata:
                    analysis["document_pages"] += item.metadata["page_count"]
                else:
                    # Assume 1 page if not specified
                    analysis["document_pages"] += 1
                    
            elif item.type == ContentType.CODE:
                analysis["code_count"] += 1
                # Count lines of code
                if isinstance(item.content, str):
                    analysis["code_lines"] += item.content.count("\n") + 1
                    analysis["token_count"] += self._estimate_token_count(item.content)
                    
            elif item.type == ContentType.JSON:
                analysis["has_json"] = True
                if isinstance(item.content, str):
                    analysis["token_count"] += self._estimate_token_count(item.content)
                elif isinstance(item.content, (dict, list)):
                    analysis["token_count"] += self._estimate_token_count(json.dumps(item.content))
                    
            elif item.type == ContentType.HTML:
                analysis["has_html"] = True
                if isinstance(item.content, str):
                    analysis["token_count"] += self._estimate_token_count(item.content)
                    
            elif item.type == ContentType.XML:
                analysis["has_xml"] = True
                if isinstance(item.content, str):
                    analysis["token_count"] += self._estimate_token_count(item.content)
                    
            elif item.type == ContentType.CSV:
                analysis["has_csv"] = True
                if isinstance(item.content, str):
                    analysis["token_count"] += self._estimate_token_count(item.content)
                    
            elif item.type == ContentType.PDF:
                analysis["has_pdf"] = True
                analysis["document_count"] += 1
                # Get page count from metadata if available
                if item.metadata and "page_count" in item.metadata:
                    analysis["document_pages"] += item.metadata["page_count"]
                    
        return analysis
    
    def _evaluate_rule_conditions(self, rule: SelectionRule, request: RoutingRequest, analysis: Dict[str, Any]) -> bool:
        """Evaluate if a rule's conditions match the request"""
        conditions = rule.conditions
        
        # Check content type conditions
        if conditions.content_type and not any(ct in conditions.content_type for ct in analysis["content_types"]):
            return False
            
        # Check task type conditions
        if conditions.task_type and request.task_type not in conditions.task_type:
            return False
            
        # Check user tier conditions
        if conditions.user_tier and request.context.user_tier not in conditions.user_tier:
            return False
            
        # Check token count conditions
        if conditions.token_count:
            if "min" in conditions.token_count and analysis["token_count"] < conditions.token_count["min"]:
                return False
            if "max" in conditions.token_count and analysis["token_count"] > conditions.token_count["max"]:
                return False
                
        # Check content count conditions
        if conditions.content_count:
            content_count = len(request.content)
            if "min" in conditions.content_count and content_count < conditions.content_count["min"]:
                return False
            if "max" in conditions.content_count and content_count > conditions.content_count["max"]:
                return False
                
        # Check page count conditions (for documents)
        if conditions.page_count:
            if "min" in conditions.page_count and analysis["document_pages"] < conditions.page_count["min"]:
                return False
            if "max" in conditions.page_count and analysis["document_pages"] > conditions.page_count["max"]:
                return False
                
        # Check local inference requirement
        if conditions.require_local_inference is not None and conditions.require_local_inference != request.context.require_local_inference:
            return False
            
        # Check streaming requirement
        if conditions.require_stream is not None and conditions.require_stream != request.context.require_stream:
            return False
            
        # Check GPU requirement
        if conditions.require_gpu is not None and conditions.require_gpu != request.context.require_gpu:
            return False
            
        # Check tags
        if conditions.tags and not any(tag in request.context.tags for tag in conditions.tags):
            return False
            
        # All conditions matched
        return True
    
    async def _validate_model_availability(self, model_id: str) -> Tuple[bool, Optional[Dict[str, Any]]]:
        """Check if a model is available and has the required capabilities"""
        try:
            model = await self.registry_client.get_model(model_id)
            capabilities = await self.registry_client.get_model_capabilities(model_id)
            
            # Check if model is active
            if not model.get("active", False):
                logger.info(f"Model {model_id} is not active")
                return False, None
                
            return True, {
                "model": model,
                "capabilities": capabilities
            }
        except Exception as e:
            logger.warning(f"Failed to validate model {model_id}: {e}")
            return False, None
    
    async def _get_fallback_models(self, model_id: str) -> List[str]:
        """Get fallback models for a given model"""
        return settings.FALLBACK_MODELS.get(model_id, [])
    
    async def _estimate_cost(self, model_id: str, token_count: int) -> Optional[float]:
        """Estimate cost for using a model with given token count"""
        try:
            capabilities = await self.registry_client.get_model_capabilities(model_id)
            
            if "pricing" in capabilities:
                # Assume a 3:1 ratio of input:output tokens if not specified
                input_tokens = token_count
                output_tokens = token_count // 3
                
                input_price = capabilities["pricing"].get("input", 0)
                output_price = capabilities["pricing"].get("output", 0)
                
                # Calculate cost per 1K tokens
                input_cost = (input_tokens / 1000) * input_price
                output_cost = (output_tokens / 1000) * output_price
                
                return input_cost + output_cost
            
            return None
        except Exception as e:
            logger.warning(f"Failed to estimate cost for model {model_id}: {e}")
            return None
    
    async def route_request(self, request: RoutingRequest) -> RoutingResponse:
        """Route a request to the most appropriate model"""
        # If force_model is specified, use it directly
        if request.force_model:
            valid, model_info = await self._validate_model_availability(request.force_model)
            if valid:
                return self._create_routing_response(
                    request,
                    request.force_model,
                    await self._get_fallback_models(request.force_model),
                    "force_model specified",
                    1.0,
                    model_info
                )
            else:
                logger.warning(f"Forced model {request.force_model} is not available")
                # Even with force_model, fall through to normal selection if unavailable
        
        # Analyze request content
        analysis = self._analyze_request_content(request)
        logger.info(f"Request analysis: {analysis}")
        
        # Handle model_preference if specified
        if request.model_preference:
            valid, model_info = await self._validate_model_availability(request.model_preference)
            if valid:
                return self._create_routing_response(
                    request,
                    request.model_preference,
                    await self._get_fallback_models(request.model_preference),
                    "model_preference specified and available",
                    0.9,
                    model_info
                )
            else:
                logger.info(f"Preferred model {request.model_preference} is not available")
                # Fall through to normal selection if preferred model unavailable
        
        # Evaluate rules in priority order
        for rule in self.rules:
            if not rule.active:
                continue
                
            # Check if rule conditions match the request
            if self._evaluate_rule_conditions(rule, request, analysis):
                logger.info(f"Rule {rule.id} matched for request {request.id}")
                
                # Validate model availability
                valid, model_info = await self._validate_model_availability(rule.model)
                if valid:
                    # Return the selected model
                    return self._create_routing_response(
                        request,
                        rule.model,
                        rule.fallback_models,
                        f"matched rule: {rule.id}",
                        0.8,
                        model_info
                    )
                else:
                    logger.warning(f"Rule {rule.id} selected model {rule.model} which is not available")
                    
                    # Try fallback models
                    for fallback in rule.fallback_models:
                        valid, model_info = await self._validate_model_availability(fallback)
                        if valid:
                            return self._create_routing_response(
                                request,
                                fallback,
                                [],  # No further fallbacks for fallbacks
                                f"fallback for rule: {rule.id}",
                                0.5,
                                model_info
                            )
        
        # If no rules matched or all selected models were unavailable,
        # use the default model
        valid, model_info = await self._validate_model_availability(settings.DEFAULT_MODEL)
        if valid:
            return self._create_routing_response(
                request,
                settings.DEFAULT_MODEL,
                await self._get_fallback_models(settings.DEFAULT_MODEL),
                "default model (no rules matched)",
                0.3,
                model_info
            )
        else:
            # If default model is unavailable, return an error
            logger.error(f"Default model {settings.DEFAULT_MODEL} is not available")
            raise Exception(f"No suitable model available for request {request.id}")
    
    async def _create_routing_response(
        self,
        request: RoutingRequest,
        model_id: str,
        fallback_models: List[str],
        routing_reason: str,
        confidence: float,
        model_info: Dict[str, Any]
    ) -> RoutingResponse:
        """Create a routing response object"""
        # Extract model and capabilities from model_info
        model = model_info["model"]
        capabilities = model_info["capabilities"]
        
        # Estimate cost
        estimated_cost = await self._estimate_cost(model_id, self._analyze_request_content(request)["token_count"])
        
        # Determine endpoint URL
        endpoint_url = model.get("endpoint_url", f"/api/v1/models/{model_id}/generate")
        
        # Determine if authentication is required
        auth_required = model.get("auth_required", True)
        
        # Create response
        response = RoutingResponse(
            request_id=request.id,
            selected_model=model_id,
            fallback_models=fallback_models,
            routing_reason=routing_reason,
            selection_confidence=confidence,
            estimated_cost=estimated_cost,
            endpoint_url=endpoint_url,
            auth_required=auth_required,
            additional_parameters={
                "provider": model.get("provider", "unknown"),
                "model_type": model.get("model_type", "unknown"),
                "version": model.get("version", "latest")
            },
            timestamp=datetime.utcnow()
        )
        
        return response
        
    async def log_routing_metrics(self, metrics: RoutingMetrics):
        """Log routing metrics for a request"""
        try:
            await self.registry_client.log_model_usage(metrics.model_id, metrics.dict())
        except Exception as e:
            logger.error(f"Failed to log routing metrics: {e}")
            # Don't raise exception for logging failures