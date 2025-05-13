import asyncio
import os
from typing import Generator
from unittest.mock import AsyncMock, MagicMock

import asyncpg
import pytest
import redis
from google.cloud import pubsub_v1

from libs.a2a_adapter import PolicyMiddleware, PubSubTransport, SupabaseTransport


@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(autouse=True)
def setup_test_env():
    """Set up test environment variables."""
    os.environ["ENVIRONMENT"] = "test"
    os.environ["PUBSUB_EMULATOR_HOST"] = "localhost:8085"
    os.environ["DATABASE_URL"] = "postgresql://postgres:postgres@localhost:5432/test_db"
    os.environ["REDIS_URL"] = "redis://localhost:6379/1"
    os.environ["GCP_PROJECT_ID"] = "test-project"


@pytest.fixture
async def test_db():
    """Provide a clean test database."""
    conn = await asyncpg.connect(os.environ["DATABASE_URL"])

    # Clean up existing data
    await conn.execute("TRUNCATE TABLE tasks, task_results, processed_messages CASCADE")

    yield conn

    await conn.close()


@pytest.fixture
def mock_pubsub():
    """Mock Pub/Sub client."""
    mock = MagicMock(spec=pubsub_v1.PublisherClient)
    mock.publish.return_value.result.return_value = "test-message-id"
    return mock


@pytest.fixture
def mock_redis():
    """Mock Redis client."""
    return MagicMock(spec=redis.Redis)


@pytest.fixture
def pubsub_transport(mock_pubsub):
    """Create PubSubTransport with mock."""
    transport = PubSubTransport(project_id="test-project")
    transport.publisher = mock_pubsub
    return transport


@pytest.fixture
async def supabase_transport(test_db):
    """Create SupabaseTransport with test database."""
    transport = SupabaseTransport(database_url=os.environ["DATABASE_URL"])
    await transport.connect()
    yield transport
    await transport.disconnect()


@pytest.fixture
def policy_middleware(mock_redis):
    """Create PolicyMiddleware with mock Redis."""
    return PolicyMiddleware(redis_client=mock_redis)
