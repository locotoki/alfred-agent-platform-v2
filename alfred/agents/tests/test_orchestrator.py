"""Tests for Agent Orchestrator."""

import pytest

from alfred.agents.orchestrator import AgentOrchestrator, orchestrator_route_total


class TestAgentOrchestrator:
    """Test the AgentOrchestrator class."""

    def setup_method(self):
        """Set up test fixtures."""
        self.orchestrator = AgentOrchestrator()
        # Clear metrics before each test
        orchestrator_route_total._metrics.clear()

    @pytest.mark.asyncio
    async def test_unknown_intent_returns_help(self):
        """Test that unknown intent returns help without LLM."""
        # Test with a message that won't match any pattern
        response = await self.orchestrator.process_message("xyzzy123456")

        assert response["status"] == "success"
        assert response["intent"] == "unknown_intent"
        assert response["confidence"] == 0.0
        assert "I didn't understand your request" in response["response"]
        assert response["llm_used"] is False

    @pytest.mark.asyncio
    async def test_unknown_intent_increments_metric(self):
        """Test that unknown intent increments the correct metric."""
        # Clear metrics
        orchestrator_route_total._metrics.clear()

        # Process an unknown intent
        await self.orchestrator.process_message("gibberish123")

        # Check that metric was incremented
        metric_value = orchestrator_route_total.labels(intent_type="unknown_intent")._value.get()
        assert metric_value == 1.0

    @pytest.mark.asyncio
    async def test_known_intent_processes_correctly(self):
        """Test that known intents are processed correctly."""
        # Test greeting
        response = await self.orchestrator.process_message("hello there")

        assert response["status"] == "success"
        assert response["intent"] == "greeting"
        assert response["confidence"] == 0.9
        assert "Hello!" in response["response"]
        assert response["llm_used"] is False

    @pytest.mark.asyncio
    async def test_help_intent(self):
        """Test help intent processing."""
        response = await self.orchestrator.process_message("help me please")

        assert response["status"] == "success"
        assert response["intent"] == "help"
        assert "I can help you with" in response["response"]
        assert response["llm_used"] is False

    @pytest.mark.asyncio
    async def test_status_intent(self):
        """Test status check intent."""
        response = await self.orchestrator.process_message("what's the status?")

        assert response["status"] == "success"
        assert response["intent"] == "status_check"
        assert "All systems are operational" in response["response"]

    @pytest.mark.asyncio
    async def test_error_handling(self):
        """Test error handling in orchestrator."""
        # Mock an error by passing None to trigger an exception
        orchestrator = AgentOrchestrator()
        # Temporarily break the router
        orchestrator._intent_router = None

        response = await orchestrator.process_message("test message")

        assert response["status"] == "error"
        assert "error" in response
        assert response["llm_used"] is False

    @pytest.mark.asyncio
    async def test_no_llm_token_increment_for_unknown(self):
        """Test that no LLM tokens are used for unknown intent."""
        # This test verifies the requirement that unknown_intent doesn't use LLM
        response = await self.orchestrator.process_message("completely unknown text")

        assert response["intent"] == "unknown_intent"
        assert response["llm_used"] is False
        # In a real system, we'd also check that no LLM token counter was incremented
        # but since we don't have LLM integration yet, we just verify the flag
