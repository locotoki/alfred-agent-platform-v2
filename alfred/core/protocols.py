"""Protocol interfaces for alfred.core module.

This module defines the abstract interfaces used throughout the alfred.core subsystem to
ensure strict typing and enable proper dependency inversion.
"""

from abc import abstractmethod
from typing import Any, Dict, Protocol


class Service(Protocol):
    """Protocol for services that have lifecycle methods"""

    @abstractmethod
    async def start(self) -> None:
        """Start the service"""
        ...
        
    @abstractmethod
    async def stop(self) -> None:
        """Stop the service gracefully"""
        ...


class HealthCheckable(Protocol):
    """Protocol for components that can report health status"""

    @abstractmethod
    async def health_check(self) -> Dict[str, Any]:
        """Check health status of the component.

        Returns:
            Dict containing health status information with at least 'status' key.
        """
        ...


class ConfigLoader(Protocol):
    """Protocol for configuration loading"""

    @abstractmethod
    def load_config(self, config_path: str) -> Dict[str, Any]:
        """Load configuration from a file path.

        Args:
            config_path: Path to configuration file.

        Returns:
            Dictionary containing configuration values.
        """
        ...

    @abstractmethod
    def validate_config(self, config: Dict[str, Any]) -> bool:
        """Validate a configuration dictionary.

        Args:
            config: Configuration dictionary to validate.

        Returns:
            True if configuration is valid, False otherwise.
        """
        ...


class CoreApplication(Protocol):
    """Protocol for the main application interface"""

    @abstractmethod
    async def start(self) -> None:
        """Start the application"""
        ...

    @abstractmethod
    async def stop(self) -> None:
        """Stop the application gracefully"""
        ...

    @abstractmethod
    async def get_status(self) -> Dict[str, Any]:
        """Get current application status.

        Returns:
            Dictionary containing status information.
        """
        ...
