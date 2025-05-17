"""Protocol interfaces for alfred.model module.

This module defines the abstract interfaces used throughout the alfred.model
subsystem for model routing, registry, and management.
"""

from abc import abstractmethod
from datetime import datetime
from typing import Any, Dict, List, Optional, Protocol


class ModelRouter(Protocol):
    """Protocol for model routing and selection."""

    @abstractmethod
    async def route_request(self, task_type: str, payload: Dict[str, Any]) -> str:
        """Route a request to the appropriate model.

        Args:
            task_type: Type of task to perform.
            payload: Request payload.

        Returns:
            Model ID to use for the task.
        """
        ...

    @abstractmethod
    async def get_available_models(self) -> List[Dict[str, Any]]:
        """Get list of available models.

        Returns:
            List of model information dictionaries.
        """
        ...

    @abstractmethod
    async def get_model_metrics(self, model_id: str) -> Dict[str, float]:
        """Get metrics for a specific model.

        Args:
            model_id: Model identifier.

        Returns:
            Dictionary of model metrics.
        """
        ...


class ModelRegistry(Protocol):
    """Protocol for model registration and discovery."""

    @abstractmethod
    async def register_model(self, model_config: Dict[str, Any]) -> str:
        """Register a new model.

        Args:
            model_config: Model configuration dictionary.

        Returns:
            Model ID of registered model.
        """
        ...

    @abstractmethod
    async def update_model(self, model_id: str, updates: Dict[str, Any]) -> bool:
        """Update an existing model's configuration.

        Args:
            model_id: Model identifier.
            updates: Configuration updates.

        Returns:
            True if update was successful.
        """
        ...

    @abstractmethod
    async def get_model(self, model_id: str) -> Optional[Dict[str, Any]]:
        """Get model configuration by ID.

        Args:
            model_id: Model identifier.

        Returns:
            Model configuration or None if not found.
        """
        ...

    @abstractmethod
    async def list_models(self, provider: Optional[str] = None) -> List[Dict[str, Any]]:
        """List all registered models.

        Args:
            provider: Optional provider filter.

        Returns:
            List of model configurations.
        """
        ...


class Model(Protocol):
    """Protocol for individual model interfaces."""

    @abstractmethod
    async def predict(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Make a prediction using the model.

        Args:
            input_data: Input data for prediction.

        Returns:
            Prediction results.
        """
        ...

    @abstractmethod
    def get_info(self) -> Dict[str, Any]:
        """Get model information.

        Returns:
            Model information dictionary.
        """
        ...

    @abstractmethod
    def get_capabilities(self) -> List[str]:
        """Get model capabilities.

        Returns:
            List of capability strings.
        """
        ...


class ModelMonitor(Protocol):
    """Protocol for model monitoring and observability."""

    @abstractmethod
    def record_prediction(self, model_id: str, duration_ms: float, success: bool) -> None:
        """Record a prediction event.

        Args:
            model_id: Model identifier.
            duration_ms: Prediction duration in milliseconds.
            success: Whether prediction was successful.
        """
        ...

    @abstractmethod
    def get_model_stats(self, model_id: str, time_window: int = 3600) -> Dict[str, Any]:
        """Get model statistics over a time window.

        Args:
            model_id: Model identifier.
            time_window: Time window in seconds.

        Returns:
            Statistics dictionary.
        """
        ...
