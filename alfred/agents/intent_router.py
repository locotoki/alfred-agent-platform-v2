"""Intent Router for Alfred agents.

This module implements the intent routing system that maps incoming messages to
appropriate handlers based on intent classification.
"""

import re
from dataclasses import dataclass
from typing import Any, Callable, Dict, Optional

import structlog
from prometheus_client import Counter

# Prometheus metrics
intents_total = Counter(
    "alfred_intents_total", "Total intents processed", ["intent_type", "status"]
)

logger = structlog.get_logger(__name__)


@dataclass
class Intent:
    """Represents a classified intent"""

    type: str
    confidence: float
    entities: Dict[str, Any]
    raw_message: str

    def __str__(self) -> str:
        return f"Intent(type={self.type}, confidence={self.confidence:.2f})"


class IntentRouter:
    """Routes messages to appropriate handlers based on intent"""

    def __init__(self) -> None:
        self._handlers: Dict[str, Callable[..., Any]] = {}
        self._patterns: Dict[str, re.Pattern[str]] = {}

        # Register default handlers
        self._register_default_handlers()

    def route(self, message: str) -> Intent:
        """Route a message to determine its intent.

        Args:
            message: The incoming message text

        Returns:
            Intent: The classified intent
        """
        # Default to unknown intent with zero confidence
        intent = Intent(
            type="unknown",
            confidence=0.0,
            entities={},
            raw_message=message,
        )

        # Try pattern matching first
        for intent_type, pattern in self._patterns.items():
            match = pattern.search(message)
            if match:
                intent.type = intent_type
                intent.confidence = 0.95
                intent.entities = match.groupdict()
                break

        # If no pattern match, we could use ML-based classification here
        if intent.type == "unknown":
            # In a real implementation, this would use an ML model
            # Here we just use some simplistic rules
            message_lower = message.lower()

            if "help" in message_lower:
                intent.type = "help"
                intent.confidence = 0.9
            elif any(word in message_lower for word in ["search", "find", "get"]):
                intent.type = "search"
                intent.confidence = 0.8
            elif any(word in message_lower for word in ["thank", "thanks", "appreciate"]):
                intent.type = "gratitude"
                intent.confidence = 0.9

        # Track the intent
        intents_total.labels(intent_type=intent.type, status="processed").inc()

        logger.info("intent_classified", type=intent.type, confidence=intent.confidence)
        return intent

    def register_handler(self, intent_type: str, handler: Callable[..., Any]) -> None:
        """Register a handler for a specific intent type.

        Args:
            intent_type: The intent type to handle
            handler: The handler function
        """
        self._handlers[intent_type] = handler
        logger.info("handler_registered", intent_type=intent_type)

    def register_pattern(self, intent_type: str, pattern: str) -> None:
        """Register a regex pattern to match a specific intent.

        Args:
            intent_type: The intent type for matches
            pattern: The regex pattern string
        """
        self._patterns[intent_type] = re.compile(pattern, re.IGNORECASE)
        logger.info("pattern_registered", intent_type=intent_type, pattern=pattern)

    def handle(self, intent: Intent, **kwargs: Any) -> Optional[str]:
        """Handle an intent by routing it to the appropriate handler.

        Args:
            intent: The intent to handle
            **kwargs: Additional keyword arguments to pass to the handler

        Returns:
            Optional[str]: The handler's response or None if no handler
        """
        handler = self._handlers.get(intent.type)
        if not handler:
            logger.warning("no_handler_for_intent", intent_type=intent.type)
            return None

        try:
            response = handler(intent=intent, **kwargs)
            intents_total.labels(intent_type=intent.type, status="handled").inc()
            return str(response) if response is not None else None
        except Exception as e:
            logger.error(
                "handler_error",
                intent_type=intent.type,
                error=str(e),
                error_type=type(e).__name__,
            )
            intents_total.labels(intent_type=intent.type, status="error").inc()
            return None

    def _register_default_handlers(self) -> None:
        """Register default intent handlers"""
        # Register a help handler
        self.register_handler("help", self._help_handler)

        # Register gratitude handler
        self.register_handler("gratitude", self._gratitude_handler)

        # Register a fallback handler for unknown intents
        self.register_handler("unknown", self._unknown_handler)

        # Register a simple pattern for greetings
        self.register_pattern("greeting", r"^(?:hi|hello|hey|greetings)(?:\s|$)")
        self.register_handler("greeting", self._greeting_handler)

    def _help_handler(self, intent: Intent, **kwargs: Any) -> str:
        """Handle help requests"""
        return "I can assist with various tasks. What would you like to know?"

    def _gratitude_handler(self, intent: Intent, **kwargs: Any) -> str:
        """Handle expressions of gratitude"""
        return "You're welcome! Is there anything else I can help with?"

    def _greeting_handler(self, intent: Intent, **kwargs: Any) -> str:
        """Handle greeting intents"""
        return "Hello! How can I assist you today?"

    def _unknown_handler(self, intent: Intent, **kwargs: Any) -> str:
        """Handle unknown intents"""
        return "I'm not sure I understand. Could you please rephrase that?"
