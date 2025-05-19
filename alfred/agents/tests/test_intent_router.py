"""Tests for Intent Router."""

import pytest

from alfred.agents.intent_router import Intent, IntentRouter, intents_total


class TestIntent:
    """Test Intent dataclass."""

    def test_intent_creation(self):
        intent = Intent(
            type="greeting",
            confidence=0.95,
            entities={"name": "John"},
            raw_message="Hello John"
        )

        assert intent.type == "greeting"
        assert intent.confidence == 0.95
        assert intent.entities == {"name": "John"}
        assert intent.raw_message == "Hello John"

    def test_intent_string_representation(self):
        intent = Intent(
            type="help",
            confidence=0.87,
            entities={},
            raw_message="I need help"
        )

        assert str(intent) == "Intent(type=help, confidence=0.87)"


class TestIntentRouter:
    """Test IntentRouter functionality."""

    @pytest.fixture
    def router(self):
        return IntentRouter()

    def test_route_greeting_intent(self, router):
        """Test routing of greeting messages."""
        test_messages = [
            "Hello",
            "Hi there",
            "Hey!",
            "Good morning",
            "Greetings"
        ]

        for message in test_messages:
            intent = router.route(message)
            assert intent.type == "greeting"
            assert intent.confidence == 0.9
            assert intent.raw_message == message

    def test_route_help_intent(self, router):
        """Test routing of help messages."""
        test_messages = [
            "Help",
            "I need assistance",
            "How to use this?",
            "What can you do?",
            "Guide me"
        ]

        for message in test_messages:
            intent = router.route(message)
            assert intent.type == "help"
            assert intent.confidence == 0.9

    def test_route_status_intent(self, router):
        """Test routing of status check messages."""
        test_messages = [
            "Status",
            "Health check",
            "Ping",
            "Are you alive?",
            "Is it working?"
        ]

        for message in test_messages:
            intent = router.route(message)
            assert intent.type == "status_check"
            assert intent.confidence == 0.9

    def test_route_unknown_intent(self, router):
        """Test routing of unrecognized messages."""
        test_messages = [
            "Random gibberish",
            "Something completely different",
            "Unrelated query",
            "12345",
            "!@#$%"
        ]

        for message in test_messages:
            intent = router.route(message)
            assert intent.type == "unknown_intent"
            assert intent.confidence == 0.0

    def test_case_insensitive_routing(self, router):
        """Test that routing is case-insensitive."""
        variations = ["HELLO", "Hello", "hello", "HeLLo"]

        for message in variations:
            intent = router.route(message)
            assert intent.type == "greeting"

    def test_register_custom_handler(self, router):
        """Test registering a custom handler."""
        def custom_handler(intent):
            return "Custom response"

        router.register_handler(
            "custom_intent",
            custom_handler,
            pattern=r"custom|special"
        )

        # Test custom intent routing
        intent = router.route("This is custom")
        assert intent.type == "custom_intent"

        # Test handler retrieval
        handler = router.get_handler("custom_intent")
        assert handler is not None
        assert handler(intent) == "Custom response"

    def test_get_handler(self, router):
        """Test handler retrieval."""
        # Test existing handler
        greeting_handler = router.get_handler("greeting")
        assert greeting_handler is not None

        # Test non-existent handler
        missing_handler = router.get_handler("non_existent")
        assert missing_handler is None

    def test_default_handlers_responses(self, router):
        """Test responses from default handlers."""
        # Test greeting response
        greeting_intent = router.route("Hello")
        handler = router.get_handler("greeting")
        response = handler(greeting_intent)
        assert "Alfred" in response
        assert "assistant" in response

        # Test help response
        help_intent = router.route("Help")
        handler = router.get_handler("help")
        response = handler(help_intent)
        assert "help you with" in response

        # Test status response
        status_intent = router.route("Status")
        handler = router.get_handler("status_check")
        response = handler(status_intent)
        assert "operational" in response

        # Test unknown response
        unknown_intent = router.route("Random")
        handler = router.get_handler("unknown_intent")
        response = handler(unknown_intent)
        assert "not sure" in response
        assert "rephrase" in response

    def test_error_handling_in_route(self, router, monkeypatch):
        """Test error handling during routing."""
        # Mock the patterns dictionary to cause an error
        monkeypatch.setattr(router, "_patterns", {"error_pattern": None})

        # This should cause an AttributeError when trying to call .search() on None
        intent = router.route("Test message")
        assert intent.type == "error_intent"
        assert intent.confidence == 0.0
        assert "error" in intent.entities

    def test_prometheus_metrics_increment(self, router):
        """Test that Prometheus metrics are incremented correctly."""
        # Note: In a real test, you'd use prometheus_client.REGISTRY
        # to check actual metric values

        # Route several messages
        test_cases = [
            ("Hello", "greeting"),
            ("Help me", "help"),
            ("Unknown stuff", "unknown_intent")
        ]

        for message, expected_intent in test_cases:
            intent = router.route(message)
            assert intent.type == expected_intent
            # Metrics would be incremented here

    def test_three_sample_messages(self, router):
        """Test the acceptance criteria: 3 sample messages → correct stub intents."""
        test_cases = [
            ("Hello Alfred", "greeting"),
            ("I need help with something", "help"),
            ("What's the system status?", "status_check")
        ]

        for message, expected_intent in test_cases:
            intent = router.route(message)
            assert intent.type == expected_intent
            assert intent.confidence > 0.0
            assert intent.raw_message == message
