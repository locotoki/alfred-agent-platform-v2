"""Tests for Agent Orchestrator"""

from unittest.mock import patchLFLFimport pytestLFLFfrom alfred.agents.orchestrator import AgentOrchestrator, route_totalLFLFLFclass TestAgentOrchestrator:LF    """Test the AgentOrchestrator class"""

    def setup_method(self):
        """Set up test fixtures"""
        self.orchestrator = AgentOrchestrator()
        # Clear metrics before each test
        route_total._metrics.clear()

    @pytest.mark.asyncio
    async def test_unknown_intent_returns_help(self):
        """Test that unknown intent returns help without LLM"""
        # Test with a message that won't match any pattern
        response = await self.orchestrator.process_message("xyzzy123456")

        assert "intent" in response
        assert "unknown" in response["intent"]
        assert "text" in response

    @pytest.mark.asyncio
    async def test_unknown_intent_increments_metric(self):
        """Test that unknown intent increments the correct metric"""
        # Clear metrics
        route_total._metrics.clear()

        # Process an unknown intent
        await self.orchestrator.process_message("gibberish123")

        # Check that metric was incremented
        metric_value = route_total.labels(intent_type="unknown").get_value()
        assert metric_value == 1.0

    @pytest.mark.asyncio
    async def test_known_intent_processes_correctly(self):
        """Test that known intents are processed correctly"""
        # Test greeting
        response = await self.orchestrator.process_message("hello there")

        assert "intent" in response
        assert response["intent"] == "greeting"
        assert "text" in response

    @pytest.mark.asyncio
    async def test_help_intent(self):
        """Test help intent processing"""
        response = await self.orchestrator.process_message("help me please")

        assert "intent" in response
        assert response["intent"] == "help"
        assert "text" in response

    @pytest.mark.asyncio
    async def test_error_handling(self):
        """Test error handling in orchestrator"""
        # Use a mock to simulate an exception
        with patch.object(
            AgentOrchestrator, "_process_intent", side_effect=Exception("Test error")
        ):
            orchestrator = AgentOrchestrator()
            response = await orchestrator.process_message("test message")

            # Check response contains error indicator
            assert "error" in str(response).lower()
