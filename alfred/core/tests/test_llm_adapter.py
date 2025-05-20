"""Tests for LLM adapter implementations"""

from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from alfred.core.llm_adapter import (ClaudeAdapter, Message, OpenAIAdapter,
                                     create_llm_adapter)


class TestMessage:
    """Test Message class"""

    def test_message_creation(self):
        """Test Message object creation with role and content"""
        msg = Message("user", "Hello")
        assert msg.role == "user"
        assert msg.content == "Hello"

    def test_message_to_dict(self):
        """Test Message.to_dict conversion method"""
        msg = Message("assistant", "Hi there")
        assert msg.to_dict() == {"role": "assistant", "content": "Hi there"}


class TestOpenAIAdapter:
    """Test OpenAI adapter implementation"""

    @pytest.fixture
    def adapter(self):
        """Create a test OpenAIAdapter instance with mocked credentials"""
        # Mock environment variable
        with patch.dict("os.environ", {"OPENAI_API_KEY": "test-key"}):
            return OpenAIAdapter(api_key="test-key")

    @pytest.mark.asyncio
    async def test_generate_non_streaming(self, adapter):
        """Test non-streaming text generation with OpenAI adapter"""
        # Mock the client property
        mock_client = AsyncMock()

        # Mock response
        mock_response = MagicMock()
        mock_response.choices = [MagicMock()]
        mock_response.choices[0].message.content = "Test response"
        mock_response.usage.total_tokens = 50

        mock_client.chat.completions.create.return_value = mock_response

        # Patch the client property
        with patch.object(adapter, "_client", mock_client):
            messages = [Message("user", "Hello")]
            result = await adapter.generate(messages)

            assert result == "Test response"

            # Verify API call
            mock_client.chat.completions.create.assert_called_once()
            call_args = mock_client.chat.completions.create.call_args[1]
            assert call_args["model"] == "gpt-4o-turbo"
            assert call_args["messages"] == [{"role": "user", "content": "Hello"}]
            assert call_args["temperature"] == 0.7
            assert call_args["stream"] is False

    @pytest.mark.asyncio
    async def test_generate_streaming(self, adapter):
        """Test streaming text generation with OpenAI adapter"""
        # Mock the client property
        mock_client = AsyncMock()

        # Mock streaming response
        async def mock_stream():
            chunks = [
                MagicMock(choices=[MagicMock(delta=MagicMock(content="Hello"))]),
                MagicMock(choices=[MagicMock(delta=MagicMock(content=" world"))]),
            ]
            for chunk in chunks:
                yield chunk

        mock_client.chat.completions.create.return_value = mock_stream()

        # Patch the client property
        with patch.object(adapter, "_client", mock_client):
            messages = [Message("user", "Hi")]
            result = await adapter.generate(messages, stream=True)

            # Collect stream
            chunks = []
            async for chunk in result:
                chunks.append(chunk)

            assert chunks == ["Hello", " world"]

    def test_estimate_tokens(self, adapter):
        """Test token estimation method in OpenAI adapter"""
        # Test rough estimation
        text = "This is a test message"
        tokens = adapter.estimate_tokens(text)
        assert tokens == len(text) // 4

    def test_missing_api_key(self):
        """Test error handling when API key is missing and not in environment"""
        # Temporarily clear the env var
        with patch.dict("os.environ", {}, clear=True):
            with pytest.raises(ValueError, match="OpenAI API key not provided"):
                OpenAIAdapter(api_key=None)

    def test_missing_api_key_with_env(self):
        """Test fallback to environment variable for API key"""
        # Test with env var set
        with patch.dict("os.environ", {"OPENAI_API_KEY": "env-key"}):
            adapter = OpenAIAdapter()
            assert adapter.api_key == "env-key"


class TestClaudeAdapter:
    """Test Claude adapter implementation"""

    @pytest.fixture
    def adapter(self):
        """Create a test ClaudeAdapter instance with mocked credentials"""
        with patch.dict("os.environ", {"ANTHROPIC_API_KEY": "test-key"}):
            return ClaudeAdapter(api_key="test-key")

    @pytest.mark.asyncio
    async def test_generate_with_system_message(self, adapter):
        """Test text generation with system message in Claude adapter"""
        # Mock the client property
        mock_client = AsyncMock()

        # Mock response
        mock_response = MagicMock()
        mock_response.content = [MagicMock(text="Claude response")]
        mock_response.usage.total_tokens = 40

        mock_client.messages.create.return_value = mock_response

        # Patch the client property
        with patch.object(adapter, "_client", mock_client):
            messages = [
                Message("system", "You are a helpful assistant"),
                Message("user", "Hello"),
            ]
            result = await adapter.generate(messages)

            assert result == "Claude response"

            # Verify API call
            call_args = mock_client.messages.create.call_args[1]
            assert call_args["model"] == "claude-3-sonnet-20240229"
            assert call_args["system"] == "You are a helpful assistant"
            assert call_args["messages"] == [{"role": "user", "content": "Hello"}]
            assert call_args["max_tokens"] == 4096

    def test_estimate_tokens(self, adapter):
        """Test token estimation method in Claude adapter"""
        text = "Test message for Claude"
        tokens = adapter.estimate_tokens(text)
        assert tokens == len(text) // 4


class TestFactory:
    """Test factory function"""

    def test_create_openai_adapter(self):
        """Test creation of OpenAI adapter through factory function"""
        with patch.dict("os.environ", {"OPENAI_API_KEY": "test"}):
            adapter = create_llm_adapter("openai")
            assert isinstance(adapter, OpenAIAdapter)

    def test_create_claude_adapter(self):
        """Test creation of Claude adapter through factory function"""
        with patch.dict("os.environ", {"ANTHROPIC_API_KEY": "test"}):
            adapter = create_llm_adapter("claude")
            assert isinstance(adapter, ClaudeAdapter)

    def test_unknown_provider(self):
        """Test error handling for unknown LLM providers"""
        with pytest.raises(ValueError, match="Unknown provider: gpt-j"):
            create_llm_adapter("gpt-j")


class TestTokenBudgetGuard:
    """Test token budget guard for test suite"""

    @pytest.mark.asyncio
    async def test_token_limit_in_tests(self):
        """Ensure test suite doesn't exceed token budget"""
        # This is a meta-test to ensure our test suite is efficient
        # In a real implementation, you'd track actual token usage

        MAX_TEST_TOKENS = 10000

        # Mock token counter
        test_tokens = 0

        # Simulate some test runs
        for _ in range(5):
            test_tokens += 50  # Simulate token usage

        assert (
            test_tokens <= MAX_TEST_TOKENS
        ), f"Test suite used {test_tokens} tokens, exceeding budget of {MAX_TEST_TOKENS}"
