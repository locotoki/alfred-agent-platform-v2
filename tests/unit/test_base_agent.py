import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime

from libs.agent_core import BaseAgent
from libs.a2a_adapter import A2AEnvelope


class TestAgent(BaseAgent):
    """Test implementation of BaseAgent."""

    async def process_task(self, envelope: A2AEnvelope) -> dict:
        return {"status": "success", "message": "Task processed"}


@pytest.fixture
def test_agent(pubsub_transport, supabase_transport, policy_middleware):
    """Create a test agent instance."""
    return TestAgent(
        name="test-agent",
        version="1.0.0",
        supported_intents=["TEST_INTENT"],
        pubsub_transport=pubsub_transport,
        supabase_transport=supabase_transport,
        policy_middleware=policy_middleware,
    )


@pytest.mark.asyncio
async def test_agent_initialization(test_agent):
    """Test agent initialization."""
    assert test_agent.name == "test-agent"
    assert test_agent.version == "1.0.0"
    assert test_agent.supported_intents == ["TEST_INTENT"]
    assert not test_agent.is_running


@pytest.mark.asyncio
async def test_agent_start_stop(test_agent):
    """Test agent start and stop lifecycle."""
    # Mock the registration and subscription
    test_agent._register_agent = AsyncMock()
    test_agent.pubsub.subscribe = AsyncMock()

    # Start agent
    await test_agent.start()
    assert test_agent.is_running
    assert test_agent._register_agent.called
    assert test_agent.pubsub.subscribe.called

    # Stop agent
    await test_agent.stop()
    assert not test_agent.is_running


@pytest.mark.asyncio
async def test_handle_message_unsupported_intent(test_agent):
    """Test handling message with unsupported intent."""
    envelope = A2AEnvelope(intent="UNSUPPORTED_INTENT", content={"test": "data"})

    # Mock methods
    test_agent.supabase.check_duplicate = AsyncMock(return_value=False)
    test_agent.supabase.update_task_status = AsyncMock()

    await test_agent._handle_message(envelope)

    # Should not process unsupported intent
    assert not test_agent.supabase.update_task_status.called


@pytest.mark.asyncio
async def test_handle_message_duplicate(test_agent):
    """Test handling duplicate message."""
    envelope = A2AEnvelope(intent="TEST_INTENT", content={"test": "data"})

    # Mock methods
    test_agent.supabase.check_duplicate = AsyncMock(return_value=True)
    test_agent.supabase.update_task_status = AsyncMock()

    await test_agent._handle_message(envelope)

    # Should not process duplicate message
    assert not test_agent.supabase.update_task_status.called


@pytest.mark.asyncio
async def test_handle_message_success(test_agent):
    """Test successful message handling."""
    envelope = A2AEnvelope(intent="TEST_INTENT", content={"test": "data"})

    # Mock methods
    test_agent.supabase.check_duplicate = AsyncMock(return_value=False)
    test_agent.supabase.update_task_status = AsyncMock()
    test_agent.supabase.store_task_result = AsyncMock()
    test_agent.pubsub.publish_task = AsyncMock()

    await test_agent._handle_message(envelope)

    # Verify task was processed
    assert test_agent.supabase.update_task_status.call_count == 2  # processing, completed
    assert test_agent.supabase.store_task_result.called
    assert test_agent.pubsub.publish_task.called


@pytest.mark.asyncio
async def test_handle_message_error(test_agent):
    """Test error handling in message processing."""
    envelope = A2AEnvelope(intent="TEST_INTENT", content={"test": "data"})

    # Mock methods
    test_agent.supabase.check_duplicate = AsyncMock(return_value=False)
    test_agent.supabase.update_task_status = AsyncMock()

    # Simulate error in process_task
    test_agent.process_task = AsyncMock(side_effect=Exception("Test error"))

    await test_agent._handle_message(envelope)

    # Verify error status was updated
    calls = test_agent.supabase.update_task_status.call_args_list
    assert len(calls) == 2
    assert calls[1][0][1] == "failed"  # Status should be "failed"
    assert "Test error" in calls[1][0][2]  # Error message should be included
