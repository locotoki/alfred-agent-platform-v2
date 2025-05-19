"""Agent Orchestrator that integrates with IntentRouter.

This module implements the orchestrator that processes messages through
the intent router and handles different intents appropriately.
"""

import structlog
from prometheus_client import Counter

from alfred.agents.intent_router import router

# Prometheus metrics
orchestrator_requests_total = Counter(
    "alfred_orchestrator_requests_total", "Total requests processed by orchestrator", ["status"]
)

orchestrator_route_total = Counter(
    "alfred_orchestrator_route_total", "Total routes processed", ["intent_type"]
)

logger = structlog.get_logger(__name__)


class AgentOrchestrator:
    """Orchestrator that processes messages through intent routing."""

    def __init__(self) -> None:
        """Initialize the orchestrator with the default intent router."""
        self._intent_router = router

    async def process_message(self, message: str, context: dict = None) -> dict:
        """Process a message through the orchestrator.

        Args:
            message: The incoming message to process
            context: Optional context information

        Returns:
            Response dictionary with result and metadata
        """
        try:
            # Route the message to determine intent
            intent = self._intent_router.route(message)

            # Track metrics
            orchestrator_route_total.labels(intent_type=intent.type).inc()

            logger.info(
                "Orchestrator routed message",
                intent_type=intent.type,
                confidence=intent.confidence,
            )

            # Handle special case for unknown_intent
            if intent.type == "unknown_intent":
                # Return help message without calling LLM
                response = {
                    "status": "success",
                    "intent": intent.type,
                    "confidence": intent.confidence,
                    "response": self._get_help_response(),
                    "llm_used": False,
                }

                orchestrator_requests_total.labels(status="success").inc()
                return response

            # For known intents, get the handler
            handler = self._intent_router.get_handler(intent.type)

            if handler:
                # Execute the handler
                result = handler(intent)

                response = {
                    "status": "success",
                    "intent": intent.type,
                    "confidence": intent.confidence,
                    "response": result,
                    "llm_used": False,  # Currently no LLM for basic handlers
                }
            else:
                # No handler found, return error
                response = {
                    "status": "error",
                    "intent": intent.type,
                    "confidence": intent.confidence,
                    "response": "No handler available for this intent",
                    "llm_used": False,
                }

            orchestrator_requests_total.labels(status="success").inc()
            return response

        except Exception as e:
            logger.error("Error processing message", error=str(e))
            orchestrator_requests_total.labels(status="error").inc()

            return {
                "status": "error",
                "error": str(e),
                "response": "An error occurred while processing your request",
                "llm_used": False,
            }

    def _get_help_response(self) -> str:
        """Get help response for unknown intents."""
        return (
            "I didn't understand your request. Here's what I can help with:\n"
            "• System health and status checks\n"
            "• Answering questions about services\n"
            "• Explaining alerts and metrics\n"
            "• General assistance\n"
            "\nTry saying 'hello', 'help', or 'status' to get started."
        )


# Global orchestrator instance
orchestrator = AgentOrchestrator()
