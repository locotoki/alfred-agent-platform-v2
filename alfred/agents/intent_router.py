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
    """Represents a classified intent."""

    type: str
    confidence: float
    entities: Dict[str, Any]
    raw_message: str

    def __str__(self) -> str:
        return f"Intent(type={self.type}, confidence={self.confidence:.2f})"


class IntentRouter:
    """Routes messages to appropriate handlers based on intent."""

    def __init__(self) -> None:
        self._handlers: Dict[str, Callable[..., Any]] = {}
        self._patterns: Dict[str, re.Pattern[str]] = {}

        # Register default handlers
        self._register_default_handlers()

    def route(self, message: str) -> Intent:.
        """Route a message to determine its intent.

        Args:
            message: The incoming message text

        Returns:
            Intent object with classification details
        """
        try:
            # Normalize message
            normalized = message.lower().strip()

            # Try pattern matching first
            for intent_type, pattern in self._patterns.items():
                if pattern.search(normalized):
                    intent = Intent(
                        type=intent_type,
                        confidence=0.9,  # High confidence for pattern match
                        entities={},
                        raw_message=message,
                    )

                    intents_total.labels(
                        intent_type=intent_type, status="success"
                    ).inc()

                    logger.info("Intent classified", intent=intent_type, confidence=0.9)

                    return intent

            # If no pattern matches, return unknown intent
            intent = Intent(
                type="unknown_intent", confidence=0.0, entities={}, raw_message=message
            )

            intents_total.labels(intent_type="unknown_intent", status="success").inc()

            return intent

        except Exception as e:
            logger.error("Error routing intent", error=str(e))
            intents_total.labels(intent_type="error", status="error").inc()

            # Return error intent
            return Intent(
                type="error_intent",
                confidence=0.0,
                entities={"error": str(e)},
                raw_message=message,
            )

    def register_handler(
        self,
        intent_type: str,
        handler: Callable[..., Any],
        pattern: Optional[str] = None,
    ) -> None:
        """Register a handler for an intent type.

        Args:
            intent_type: The intent type to handle
            handler: Callable to handle the intent
            pattern: Optional regex pattern for intent detection.
        """
        self._handlers[intent_type] = handler

        if pattern:
            self._patterns[intent_type] = re.compile(pattern, re.IGNORECASE)

        logger.info(
            "Handler registered", intent_type=intent_type, has_pattern=bool(pattern)
        )

    def get_handler(self, intent_type: str) -> Optional[Callable[..., Any]]:
        """Get handler for an intent type.

        Args:
            intent_type: The intent type

        Returns:
            Handler callable or None.
        """
        return self._handlers.get(intent_type)

    def _register_default_handlers(self) -> None:
        """Register default intent handlers."""
        # Greeting intent
        self.register_handler(
            "greeting",
            self._handle_greeting,
            pattern=r"\b(hello|hi|hey|greetings|good morning|good afternoon|good evening)\b",
        )

        # Help intent
        self.register_handler(
            "help",
            self._handle_help,
            pattern=r"(help|assist|how to|what can you|guide|tutorial)",
        )

        # Status check intent
        self.register_handler(
            "status_check",
            self._handle_status,
            pattern=r"\b(status|health|ping|alive|working)\b",
        )

        # Unknown intent
        self.register_handler("unknown_intent", self._handle_unknown)

    def _handle_greeting(self, intent: Intent) -> str:
        """Handle greeting intent."""
        return "Hello! I'm Alfred, your AI assistant. How can I help you today?"

    def _handle_help(self, intent: Intent) -> str:
        """Handle help intent."""
        return (
            "I can help you with:\n"
            "• Checking system status\n"
            "• Explaining alerts and metrics\n"
            "• Answering questions about our services\n"
            "• Providing technical assistance\n"
            "\nWhat would you like help with?"
        )

    def _handle_status(self, intent: Intent) -> str:
        """Handle status check intent."""
        return "All systems are operational. Alfred is ready to assist!"

    def _handle_unknown(self, intent: Intent) -> str:
        """Handle unknown intent with polite error."""
        return (
            "I'm not sure what you're asking for. "
            "Could you please rephrase or try asking differently? "
            "Type 'help' to see what I can do."
        )


# Global router instance
router = IntentRouter()
