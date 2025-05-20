"""Slack diagnostics bot for Alfred platform"""

from typing import Optional, cast

import httpx
import structlog
from slack_sdk.web.async_client import AsyncWebClient
from slack_sdk.web.slack_response import SlackResponse

logger = structlog.get_logger()


class DiagnosticsBot:
    """Slack bot for system diagnostics and health checks"""

    def __init__(
        self,
        slack_client: AsyncWebClient,
        prometheus_url: str = "http://prometheus:9090",
        enabled: bool = True,
    ) -> None:
        """Initialize diagnostics bot.

        Args:
            slack_client: Slack Web API client
            prometheus_url: URL for Prometheus API
            enabled: Whether bot is enabled.
        """
        self.slack_client = slack_client
        self.prometheus_url = prometheus_url
        self.enabled = enabled
        self.commands = {
            "/diag health": self._handle_health_command,
            "/diag metrics": self._handle_metrics_command,
        }

    async def handle_command(
        self, command: str, channel: str, user: str, text: str
    ) -> Optional[SlackResponse]:
        """Handle incoming slash command.

        Args:
            command: Command name (e.g., "/diag")
            channel: Channel ID where command was issued
            user: User ID who issued command
            text: Command arguments
        """
        if not self.enabled:
            logger.info("diagnostics_bot_disabled", command=command)
            return None

        full_command = f"{command} {text}".strip()
        logger.info("processing_command", command=full_command, channel=channel, user=user)

        handler = self.commands.get(full_command)
        if not handler:
            return await self._send_help(channel)

        try:
            return await handler(channel, user)
        except Exception as e:
            logger.error("command_error", command=full_command, error=str(e))
            return cast(
                SlackResponse,
                await self.slack_client.chat_postMessage(
                    channel=channel,
                    text=f"❌ Error executing command: {str(e)}",
                ),
            )

    async def _handle_health_command(self, channel: str, user: str) -> SlackResponse:
        """Handle health check command"""
        try:
            async with httpx.AsyncClient() as client:
                # Check each service health endpoint
                services = [
                    ("alfred-core", "http://alfred-core:8000/health"),
                    ("mission-control", "http://mission-control:3000/health"),
                    ("social-intel", "http://social-intel:5002/health"),
                    ("model-registry", "http://model-registry:8001/health"),
                    ("model-router", "http://model-router:8002/health"),
                ]

                blocks = [
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": "🏥 *Service Health Status*",
                        },
                    }
                ]

                for service_name, url in services:
                    try:
                        response = await client.get(url, timeout=5.0)
                        status = "✅" if response.status_code == 200 else "❌"
                        health_data = response.json()
                        status_text = health_data.get("status", "unknown")
                    except Exception as e:
                        status = "❌"
                        status_text = str(e)

                    blocks.append(
                        {
                            "type": "section",
                            "text": {
                                "type": "mrkdwn",
                                "text": f"{status} *{service_name}*: {status_text}",
                            },
                        }
                    )

                return cast(
                    SlackResponse,
                    await self.slack_client.chat_postMessage(channel=channel, blocks=blocks),
                )

        except Exception as e:
            logger.error("health_check_error", error=str(e))
            raise

    async def _handle_metrics_command(self, channel: str, user: str) -> SlackResponse:
        """Handle metrics query command"""
        try:
            async with httpx.AsyncClient() as client:
                # Query Prometheus for key metrics
                queries = {
                    "Request Rate": "sum(rate(http_requests_total[5m]))",
                    "Error Rate": 'sum(rate(http_requests_total{status=~"5.."}[5m]))',
                    "P95 Latency": (
                        "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
                    ),
                    "Active Agents": 'up{job=~".*agent.*"}',
                }

                blocks = [
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": "📊 *System Metrics*",
                        },
                    }
                ]

                for metric_name, query in queries.items():
                    try:
                        response = await client.get(
                            f"{self.prometheus_url}/api/v1/query",
                            params={"query": query},
                            timeout=5.0,
                        )
                        data = response.json()

                        if data["status"] == "success" and data["data"]["result"]:
                            value = data["data"]["result"][0]["value"][1]
                            # Format based on metric type
                            if "Rate" in metric_name:
                                formatted_value = f"{float(value):.2f} req/s"
                            elif "Latency" in metric_name:
                                formatted_value = f"{float(value)*1000:.2f} ms"
                            else:
                                formatted_value = value
                        else:
                            formatted_value = "No data"

                    except Exception as e:
                        formatted_value = f"Error: {str(e)}"

                    blocks.append(
                        {
                            "type": "section",
                            "text": {
                                "type": "mrkdwn",
                                "text": f"*{metric_name}*: {formatted_value}",
                            },
                        }
                    )

                return cast(
                    SlackResponse,
                    await self.slack_client.chat_postMessage(channel=channel, blocks=blocks),
                )

        except Exception as e:
            logger.error("metrics_query_error", error=str(e))
            raise

    async def _send_help(self, channel: str) -> SlackResponse:
        """Send help message"""
        blocks = [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "🤖 *Diagnostics Bot Commands*",
                },
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": "• `/diag health` - Check service health status\n"
                    "• `/diag metrics` - View system metrics",
                },
            },
        ]

        return cast(
            SlackResponse,
            await self.slack_client.chat_postMessage(channel=channel, blocks=blocks),
        )
