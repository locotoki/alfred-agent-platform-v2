"""Protocol interfaces for alfred.infrastructure module.

This module defines the abstract interfaces used throughout the alfred.infrastructure
subsystem for infrastructure management and orchestration.
"""

from typing import Protocol, Dict, Any, List, Optional, Callable
from abc import abstractmethod


class ServiceDiscovery(Protocol):
    """Protocol for service discovery and registration."""
    
    @abstractmethod
    async def register_service(self, service_name: str, service_info: Dict[str, Any]) -> bool:
        """Register a service with discovery system.
        
        Args:
            service_name: Name of the service.
            service_info: Service information including host, port, etc.
            
        Returns:
            True if registration was successful.
        """
        ...
    
    @abstractmethod
    async def discover_service(self, service_name: str) -> Optional[Dict[str, Any]]:
        """Discover a service by name.
        
        Args:
            service_name: Name of the service to discover.
            
        Returns:
            Service information or None if not found.
        """
        ...
    
    @abstractmethod
    async def list_services(self, service_type: Optional[str] = None) -> List[Dict[str, Any]]:
        """List all registered services.
        
        Args:
            service_type: Optional filter by service type.
            
        Returns:
            List of service information dictionaries.
        """
        ...
    
    @abstractmethod
    async def health_check(self, service_name: str) -> bool:
        """Check health of a service.
        
        Args:
            service_name: Name of the service.
            
        Returns:
            True if service is healthy.
        """
        ...


class ConfigurationManager(Protocol):
    """Protocol for configuration management."""
    
    @abstractmethod
    def get_config(self, key: str, default: Any = None) -> Any:
        """Get configuration value.
        
        Args:
            key: Configuration key.
            default: Default value if key not found.
            
        Returns:
            Configuration value.
        """
        ...
    
    @abstractmethod
    def set_config(self, key: str, value: Any) -> None:
        """Set configuration value.
        
        Args:
            key: Configuration key.
            value: Configuration value.
        """
        ...
    
    @abstractmethod
    def reload_config(self) -> None:
        """Reload configuration from source."""
        ...
    
    @abstractmethod
    def validate_config(self) -> bool:
        """Validate current configuration.
        
        Returns:
            True if configuration is valid.
        """
        ...


class SecretManager(Protocol):
    """Protocol for secret management."""
    
    @abstractmethod
    async def get_secret(self, secret_name: str) -> Optional[str]:
        """Retrieve a secret value.
        
        Args:
            secret_name: Name of the secret.
            
        Returns:
            Secret value or None if not found.
        """
        ...
    
    @abstractmethod
    async def set_secret(self, secret_name: str, secret_value: str) -> bool:
        """Store a secret value.
        
        Args:
            secret_name: Name of the secret.
            secret_value: Secret value to store.
            
        Returns:
            True if storage was successful.
        """
        ...
    
    @abstractmethod
    async def rotate_secret(self, secret_name: str) -> str:
        """Rotate a secret value.
        
        Args:
            secret_name: Name of the secret to rotate.
            
        Returns:
            New secret value.
        """
        ...


class QueueManager(Protocol):
    """Protocol for message queue management."""
    
    @abstractmethod
    async def publish(self, topic: str, message: Dict[str, Any]) -> bool:
        """Publish a message to a topic.
        
        Args:
            topic: Topic name.
            message: Message payload.
            
        Returns:
            True if publish was successful.
        """
        ...
    
    @abstractmethod
    async def subscribe(self, topic: str, handler: Callable[[Dict[str, Any]], None]) -> str:
        """Subscribe to a topic.
        
        Args:
            topic: Topic name.
            handler: Message handler function.
            
        Returns:
            Subscription ID.
        """
        ...
    
    @abstractmethod
    async def unsubscribe(self, subscription_id: str) -> bool:
        """Unsubscribe from a topic.
        
        Args:
            subscription_id: Subscription ID to cancel.
            
        Returns:
            True if unsubscribe was successful.
        """
        ...


class CacheManager(Protocol):
    """Protocol for distributed cache management."""
    
    @abstractmethod
    async def get(self, key: str) -> Optional[Any]:
        """Get value from cache.
        
        Args:
            key: Cache key.
            
        Returns:
            Cached value or None.
        """
        ...
    
    @abstractmethod
    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """Set value in cache.
        
        Args:
            key: Cache key.
            value: Value to cache.
            ttl: Time to live in seconds.
            
        Returns:
            True if set was successful.
        """
        ...
    
    @abstractmethod
    async def delete(self, key: str) -> bool:
        """Delete value from cache.
        
        Args:
            key: Cache key.
            
        Returns:
            True if deletion was successful.
        """
        ...
    
    @abstractmethod
    async def clear(self, pattern: Optional[str] = None) -> int:
        """Clear cache entries.
        
        Args:
            pattern: Optional pattern to match keys.
            
        Returns:
            Number of entries cleared.
        """
        ...