#!/usr/bin/env python3
"""Test the diagnostics bot locally without Kubernetes."""

import asyncio
from unittest.mock import AsyncMock, MagicMock
import json

from alfred.slack.diagnostics import DiagnosticsBot


async def test_local_diagnostics():
    """Test diagnostics bot commands locally."""
    # Mock Slack client
    slack_client = AsyncMock()
    slack_client.chat_postMessage = AsyncMock()

    # Create bot with mocked services
    bot = DiagnosticsBot(
        slack_client=slack_client,
        prometheus_url="http://localhost:9090",  # Local Prometheus if available
        enabled=True,
    )

    print("🧪 Testing Diagnostics Bot Locally\n")

    # Test /diag health
    print("1. Testing /diag health command:")
    await bot.handle_command("/diag", "test-channel", "test-user", "health")

    health_response = slack_client.chat_postMessage.call_args
    if health_response:
        blocks = health_response.kwargs.get("blocks", [])
        print("   Response:")
        for block in blocks:
            if block["type"] == "section":
                print(f"   {block['text']['text']}")

    print("\n2. Testing /diag metrics command:")
    await bot.handle_command("/diag", "test-channel", "test-user", "metrics")

    metrics_response = slack_client.chat_postMessage.call_args
    if metrics_response:
        blocks = metrics_response.kwargs.get("blocks", [])
        print("   Response:")
        for block in blocks:
            if block["type"] == "section":
                print(f"   {block['text']['text']}")

    print("\n✅ Local testing complete!")
    print("\nTo use in production:")
    print("1. Deploy to your cluster when ready")
    print("2. Configure Slack app with slash commands")
    print("3. Set SLACK_BOT_TOKEN environment variable")
    print("4. Enable diagnostics in Helm values")


if __name__ == "__main__":
    asyncio.run(test_local_diagnostics())
