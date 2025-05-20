"""Protocol interfaces for alfred.llm module.

This module defines the abstract interfaces used throughout the alfred.llm
subsystem for language model interactions and management.
"""

from abc import abstractmethod
from typing import Any, AsyncIterator, Dict, List, Optional, Protocol


class LLMProvider(Protocol):
    """Protocol for LLM provider interfaces."""

    @abstractmethod
    async def generate(
        self, prompt: str, config: Optional[Dict[str, Any]] = None
    ) -> str:
        """Generate text from a prompt.

        Args:
            prompt: Input prompt.
            config: Optional generation configuration.

        Returns:
            Generated text.
        """
        ...

    @abstractmethod
    async def generate_stream(
        self, prompt: str, config: Optional[Dict[str, Any]] = None
    ) -> AsyncIterator[str]:
        """Generate text stream from a prompt.

        Args:
            prompt: Input prompt.
            config: Optional generation configuration.

        Yields:
            Generated text chunks.
        """
        ...

    @abstractmethod
    async def chat_completion(
        self, messages: List[Dict[str, str]], config: Optional[Dict[str, Any]] = None
    ) -> str:
        """Generate chat completion.

        Args:
            messages: List of message dictionaries with 'role' and 'content'.
            config: Optional generation configuration.

        Returns:
            Assistant's response.
        """
        ...

    @abstractmethod
    def get_model_info(self) -> Dict[str, Any]:
        """Get information about the model.

        Returns:
            Model information dictionary.
        """
        ...


class LLMRouter(Protocol):
    """Protocol for routing requests to appropriate LLM providers."""

    @abstractmethod
    async def route(self, task_type: str, input_data: Dict[str, Any]) -> str:
        """Route request to appropriate LLM provider.

        Args:
            task_type: Type of task.
            input_data: Input data for the task.

        Returns:
            Provider ID to use.
        """
        ...

    @abstractmethod
    def register_provider(self, provider_id: str, provider: LLMProvider) -> None:
        """Register a new LLM provider.

        Args:
            provider_id: Unique provider identifier.
            provider: Provider instance.
        """
        ...

    @abstractmethod
    def get_providers(self) -> Dict[str, LLMProvider]:
        """Get all registered providers.

        Returns:
            Dictionary of provider ID to provider instance.
        """
        ...


class PromptTemplate(Protocol):
    """Protocol for prompt template management."""

    @abstractmethod
    def format(self, **kwargs: Any) -> str:
        """Format the template with given variables.

        Args:
            **kwargs: Template variables.

        Returns:
            Formatted prompt string.
        """
        ...

    @abstractmethod
    def get_variables(self) -> List[str]:
        """Get list of template variables.

        Returns:
            List of variable names.
        """
        ...

    @abstractmethod
    def validate(self, **kwargs: Any) -> bool:
        """Validate that all required variables are provided.

        Args:
            **kwargs: Template variables.

        Returns:
            True if all required variables are present.
        """
        ...


class TokenCounter(Protocol):
    """Protocol for token counting and cost estimation."""

    @abstractmethod
    def count_tokens(self, text: str, model: str) -> int:
        """Count tokens in text for a specific model.

        Args:
            text: Text to count tokens for.
            model: Model name.

        Returns:
            Token count.
        """
        ...

    @abstractmethod
    def estimate_cost(
        self, token_count: int, model: str, operation: str = "completion"
    ) -> float:
        """Estimate cost for token usage.

        Args:
            token_count: Number of tokens.
            model: Model name.
            operation: Type of operation (completion, embedding, etc.).

        Returns:
            Estimated cost in USD.
        """
        ...


class LLMCache(Protocol):
    """Protocol for LLM response caching."""

    @abstractmethod
    async def get(self, key: str) -> Optional[str]:
        """Get cached response.

        Args:
            key: Cache key.

        Returns:
            Cached response or None.
        """
        ...

    @abstractmethod
    async def set(self, key: str, value: str, ttl: Optional[int] = None) -> None:
        """Set cached response.

        Args:
            key: Cache key.
            value: Response to cache.
            ttl: Time to live in seconds.
        """
        ...

    @abstractmethod
    async def invalidate(self, pattern: str) -> int:
        """Invalidate cache entries matching pattern.

        Args:
            pattern: Pattern to match keys.

        Returns:
            Number of entries invalidated.
        """
        ...
