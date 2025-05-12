"""
Resilience utilities for service interactions.
"""
import asyncio
import functools
import logging
import random
from typing import Callable, TypeVar, Any, Optional, List, Dict, Tuple, Union

T = TypeVar("T")
logger = logging.getLogger(__name__)

def with_retry(
    max_attempts: int = 3,
    initial_backoff: float = 0.5,
    max_backoff: float = 5.0,
    backoff_multiplier: float = 2.0,
    retryable_exceptions: tuple = (Exception,),
    jitter: bool = True,
):
    """Decorator for functions that should be retried on failure.
    
    Args:
        max_attempts: Maximum number of times to retry the function
        initial_backoff: Initial backoff time in seconds
        max_backoff: Maximum backoff time in seconds
        backoff_multiplier: Multiplier for backoff after each attempt
        retryable_exceptions: Tuple of exceptions that should trigger a retry
        jitter: Whether to add random jitter to the backoff time
        
    Returns:
        Decorated function with retry logic
    """
    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @functools.wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> T:
            attempt = 0
            current_backoff = initial_backoff
            
            while True:
                attempt += 1
                try:
                    return await func(*args, **kwargs)
                except retryable_exceptions as e:
                    if attempt >= max_attempts:
                        logger.error(
                            f"Failed after {attempt} attempts: {str(e)}",
                            extra={"error": str(e), "function": func.__name__}
                        )
                        raise
                    
                    # Calculate backoff with optional jitter
                    if jitter:
                        jitter_amount = random.uniform(0, 0.1 * current_backoff)
                        sleep_time = current_backoff + jitter_amount
                    else:
                        sleep_time = current_backoff
                    
                    logger.warning(
                        f"Attempt {attempt} failed, retrying in {sleep_time:.2f}s: {str(e)}",
                        extra={"error": str(e), "function": func.__name__, "attempt": attempt}
                    )
                    await asyncio.sleep(sleep_time)
                    current_backoff = min(
                        current_backoff * backoff_multiplier, max_backoff
                    )
        
        return wrapper
    return decorator

class CircuitBreaker:
    """Circuit breaker pattern implementation to prevent repeated calls to failing services."""
    
    def __init__(
        self, 
        failure_threshold: int = 5,
        reset_timeout: float = 30.0,
        half_open_timeout: float = 5.0,
    ):
        """Initialize the circuit breaker.
        
        Args:
            failure_threshold: Number of failures before circuit opens
            reset_timeout: Time in seconds to wait before attempting to close circuit
            half_open_timeout: Time in seconds to wait in half-open state
        """
        self.failure_threshold = failure_threshold
        self.reset_timeout = reset_timeout
        self.half_open_timeout = half_open_timeout
        
        self.failure_count = 0
        self.last_failure_time = 0
        self.state = "closed"  # closed, open, half-open
    
    def __call__(self, func: Callable[..., T]) -> Callable[..., T]:
        """Decorator to wrap a function with circuit breaker logic."""
        
        @functools.wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> T:
            if self._is_open():
                raise CircuitBreakerOpenError(f"Circuit is open for {func.__name__}")
            
            try:
                result = await func(*args, **kwargs)
                self._on_success()
                return result
            except Exception as e:
                self._on_failure()
                raise
        
        return wrapper
    
    def _is_open(self) -> bool:
        """Check if the circuit is open."""
        now = asyncio.get_event_loop().time()
        
        if self.state == "open":
            # Check if reset timeout has passed
            if now - self.last_failure_time >= self.reset_timeout:
                self.state = "half-open"
                logger.info(f"Circuit changed from open to half-open")
                return False
            return True
        
        if self.state == "half-open":
            # In half-open state, allow one request through
            if now - self.last_failure_time >= self.half_open_timeout:
                return False
            return True
        
        return False
    
    def _on_success(self) -> None:
        """Handle successful call."""
        if self.state == "half-open":
            self.state = "closed"
            self.failure_count = 0
            logger.info(f"Circuit changed from half-open to closed")
    
    def _on_failure(self) -> None:
        """Handle failed call."""
        self.failure_count += 1
        self.last_failure_time = asyncio.get_event_loop().time()
        
        if self.state == "closed" and self.failure_count >= self.failure_threshold:
            self.state = "open"
            logger.warning(f"Circuit changed from closed to open after {self.failure_count} failures")
        
        if self.state == "half-open":
            self.state = "open"
            logger.warning(f"Circuit changed from half-open to open after a failure")

class CircuitBreakerOpenError(Exception):
    """Exception raised when circuit breaker is open."""
    pass