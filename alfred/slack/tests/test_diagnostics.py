"""Tests for Slack diagnostics bot"""

from unittest.mock import AsyncMock, MagicMock, patch

import httpx  # type: ignore[import-not-found]
import pytest
from slack_sdk.web.async_client import AsyncWebClient

from alfred.slack.diagnostics import DiagnosticsBot


class TestDiagnosticsBot:
    """Test cases for DiagnosticsBot"""

    @pytest.fixture
    def slack_client(self) -> AsyncMock:
        """Mock Slack client"""
        client = AsyncMock(spec=AsyncWebClient)
        client.chat_postMessage = AsyncMock()
        return client

    @pytest.fixture
    def bot(self, slack_client: AsyncMock) -> DiagnosticsBot:
        """Create diagnostics bot instance"""
        return DiagnosticsBot(
            slack_client=slack_client,
            prometheus_url="http://test-prometheus:9090",
            enabled=True,
        )

    @pytest.mark.asyncio
    async def test_disabled_bot(self, slack_client: AsyncMock) -> None:
        """Test bot when disabled"""
        bot = DiagnosticsBot(slack_client=slack_client, enabled=False)
        result = await bothandle_command("/diag", "C123", "U456", "health")
        assert result is None
        slack_client.chat_postMessage.assert_not_called()

    @pytest.mark.asyncio
    async def test_unknown_command(self, bot: DiagnosticsBot, slack_client: AsyncMock) -> None:
        """Test handling unknown command"""
        await bothandle_command("/diag", "C123", "U456", "unknown")
        slack_client.chat_postMessage.assert_called_once()
        call_args = slack_client.chat_postMessage.call_args
        assert "Commands" in str(call_args)

    @pytest.mark.asyncio
    async def test_command_error(self, bot: DiagnosticsBot, slack_client: AsyncMock) -> None:
        """Test command error handling"""
        # Mock the command dictionary entry to raise an exception
        bot.commands["/diag health"] = AsyncMock(side_effect=Exception("Test error"))

        await bothandle_command("/diag", "C123", "U456", "health")

        slack_client.chat_postMessage.assert_called_once()
        call_args = slack_client.chat_postMessage.call_args
        assert call_args is not None
        assert "text" in call_args.kwargs
        assert "Error executing command" in call_args.kwargs["text"]

    @pytest.mark.asyncio
    @patch("httpx.AsyncClient")
    async def test_health_command_success(
        self,
        mock_httpx: MagicMock,
        bot: DiagnosticsBot,
        slack_client: AsyncMock,
    ) -> None:
        """Test successful health check command"""
        # Mock httpx responses
        mock_client = AsyncMock()
        mock_httpx.return_value.__aenter__.return_value = mock_client

        # Mock successful health responses
        health_response = MagicMock()
        health_response.status_code = 200
        health_response.json.return_value = {"status": "healthy"}
        mock_client.get.return_value = health_response

        await bothandle_command("/diag", "C123", "U456", "health")

        # Verify Slack message sent
        slack_client.chat_postMessage.assert_called_once()
        call_args = slack_client.chat_postMessage.call_args
        blocks = call_args.kwargs["blocks"]

        # Check message structure
        assert blocks[0]["text"]["text"] == "🏥 *Service Health Status*"
        assert len(blocks) > 1  # Should have service status entries
        assert "✅" in str(blocks)  # Should show success

    @pytest.mark.asyncio
    @patch("httpx.AsyncClient")
    async def test_health_command_service_down(
        self,
        mock_httpx: MagicMock,
        bot: DiagnosticsBot,
        slack_client: AsyncMock,
    ) -> None:
        """Test health check with service down"""
        mock_client = AsyncMock()
        mock_httpx.return_value.__aenter__.return_value = mock_client

        # Mock failed health response
        mock_client.get.side_effect = httpx.ConnectError("Connection refused")

        await bothandle_command("/diag", "C123", "U456", "health")

        slack_client.chat_postMessage.assert_called_once()
        call_args = slack_client.chat_postMessage.call_args
        blocks = call_args.kwargs["blocks"]
        assert "❌" in str(blocks)  # Should show failure

    @pytest.mark.asyncio
    @patch("httpx.AsyncClient")
    async def test_metrics_command_success(
        self,
        mock_httpx: MagicMock,
        bot: DiagnosticsBot,
        slack_client: AsyncMock,
    ) -> None:
        """Test successful metrics command"""
        mock_client = AsyncMock()
        mock_httpx.return_value.__aenter__.return_value = mock_client

        # Mock Prometheus response
        prom_response = MagicMock()
        prom_response.json.return_value = {
            "status": "success",
            "data": {"result": [{"value": [1234567890, "42.5"]}]},
        }
        mock_client.get.return_value = prom_response

        await bothandle_command("/diag", "C123", "U456", "metrics")

        slack_client.chat_postMessage.assert_called_once()
        call_args = slack_client.chat_postMessage.call_args
        blocks = call_args.kwargs["blocks"]

        assert blocks[0]["text"]["text"] == "📊 *System Metrics*"
        assert len(blocks) > 1  # Should have metric entries

    @pytest.mark.asyncio
    @patch("httpx.AsyncClient")
    async def test_metrics_command_no_data(
        self,
        mock_httpx: MagicMock,
        bot: DiagnosticsBot,
        slack_client: AsyncMock,
    ) -> None:
        """Test metrics command with no data"""
        mock_client = AsyncMock()
        mock_httpx.return_value.__aenter__.return_value = mock_client

        # Mock empty Prometheus response
        prom_response = MagicMock()
        prom_response.json.return_value = {"status": "success", "data": {"result": []}}
        mock_client.get.return_value = prom_response

        await bothandle_command("/diag", "C123", "U456", "metrics")

        slack_client.chat_postMessage.assert_called_once()
        call_args = slack_client.chat_postMessage.call_args
        blocks = call_args.kwargs["blocks"]
        assert "No data" in str(blocks)
