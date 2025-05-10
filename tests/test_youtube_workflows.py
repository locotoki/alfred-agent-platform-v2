"""Tests for YouTube workflows in SocialIntelligence Agent."""

import os
import asyncio
import pytest
import json
from datetime import datetime
from unittest.mock import AsyncMock, patch, MagicMock

from agents.social_intel.agent import SocialIntelAgent
from agents.social_intel.models.youtube_models import NicheScoutResult, BlueprintResult
from agents.social_intel.models.youtube_vectors import YouTubeVectorStorage
from libs.a2a_adapter import A2AEnvelope


@pytest.fixture
def mock_youtube_api():
    """Mock YouTubeAPI."""
    with patch('agents.social_intel.models.youtube_api.YouTubeAPI') as mock:
        # Setup mock methods
        instance = mock.return_value
        instance.search_videos = AsyncMock(return_value=[
            {
                "id": "test_video_id",
                "title": "Test Video",
                "viewCount": {"text": "1,000"}
            }
        ])
        instance.get_trend_data = AsyncMock(return_value={
            "query": "test_query",
            "current_value": 75.0,
            "values": {}
        })
        instance.search_channels = AsyncMock(return_value=[
            {
                "id": "test_channel_id",
                "title": "Test Channel",
                "subscribers": "100K"
            }
        ])
        instance.get_video_metadata = AsyncMock(return_value={
            "id": "test_video_id",
            "title": "Test Video",
            "tags": ["test", "video", "youtube"],
            "description": "This is a test video"
        })
        yield instance


@pytest.fixture
def mock_vector_storage():
    """Mock YouTubeVectorStorage."""
    with patch('agents.social_intel.models.youtube_vectors.YouTubeVectorStorage') as mock:
        # Setup mock methods
        instance = mock.return_value
        instance.initialize_collections = AsyncMock()
        instance.store_niche_vector = AsyncMock()
        instance.store_channel_vector = AsyncMock()
        instance.store_video_vector = AsyncMock()
        instance.store_ephemeral_vector = AsyncMock()
        instance.search_similar_channels = AsyncMock(return_value=[])
        instance.search_similar_videos = AsyncMock(return_value=[])
        yield instance


@pytest.fixture
def mock_youtube_niche_scout_flow():
    """Mock youtube_niche_scout_flow."""
    with patch('agents.social_intel.flows.youtube_flows.youtube_niche_scout_flow') as mock:
        # Setup mock return value
        mock.return_value = NicheScoutResult(
            run_date=datetime.now(),
            trending_niches=[],
            top_niches=[],
            visualization_url=None
        )
        yield mock


@pytest.fixture
def mock_youtube_blueprint_flow():
    """Mock youtube_blueprint_flow."""
    with patch('agents.social_intel.flows.youtube_flows.youtube_blueprint_flow') as mock:
        # Setup mock return value
        mock.return_value = BlueprintResult(
            run_date=datetime.now(),
            seed_url="https://youtu.be/test_video_id",
            seed_data={},
            top_channels=[],
            gap_analysis=[],
            blueprint={
                "positioning": "Test positioning",
                "content_pillars": ["Test Pillar 1", "Test Pillar 2"],
                "format_mix": {"long_form": 0.6, "shorts": 0.4},
                "roadmap": {"Week 1": ["Test video idea"]},
                "ai_production_tips": ["Test tip"],
                "coppa_checklist": [{"item": "Test item", "status": "Required"}]
            },
            blueprint_url="/tmp/test_blueprint.zip"
        )
        yield mock


@pytest.fixture
def mock_agent(mock_youtube_api, mock_vector_storage, mock_youtube_niche_scout_flow, mock_youtube_blueprint_flow):
    """Create a mock SocialIntelAgent."""
    # Create mock dependencies
    mock_pubsub = MagicMock()
    mock_supabase = MagicMock()
    mock_supabase._pool = MagicMock()
    mock_policy = MagicMock()
    
    # Create agent
    agent = SocialIntelAgent(
        pubsub_transport=mock_pubsub,
        supabase_transport=mock_supabase,
        policy_middleware=mock_policy
    )
    
    # Replace vector storage and YouTube API
    agent.youtube_vectors = mock_vector_storage
    agent.youtube_api = mock_youtube_api
    
    return agent


@pytest.mark.asyncio
async def test_youtube_niche_scout(mock_agent, mock_youtube_niche_scout_flow):
    """Test YOUTUBE_NICHE_SCOUT intent."""
    # Create test envelope
    envelope = A2AEnvelope(
        intent="YOUTUBE_NICHE_SCOUT",
        data={
            "queries": ["test query 1", "test query 2"]
        },
        task_id="test_task_id",
        trace_id="test_trace_id"
    )
    
    # Call method
    result = await mock_agent._youtube_niche_scout(envelope.data)
    
    # Verify result
    assert result["status"] == "success"
    assert result["type"] == "youtube_niche_scout"
    assert "trending_niches" in result
    assert "top_niches" in result
    
    # Verify flow was called with correct arguments
    mock_youtube_niche_scout_flow.assert_called_once_with(
        queries=["test query 1", "test query 2"],
        vector_storage=mock_agent.youtube_vectors
    )


@pytest.mark.asyncio
async def test_youtube_blueprint(mock_agent, mock_youtube_blueprint_flow):
    """Test YOUTUBE_BLUEPRINT intent."""
    # Create test envelope
    envelope = A2AEnvelope(
        intent="YOUTUBE_BLUEPRINT",
        data={
            "seed_url": "https://youtu.be/test_video_id",
            "auto_niche": False
        },
        task_id="test_task_id",
        trace_id="test_trace_id"
    )
    
    # Call method
    result = await mock_agent._youtube_blueprint(envelope.data)
    
    # Verify result
    assert result["status"] == "success"
    assert result["type"] == "youtube_blueprint"
    assert "top_channels" in result
    assert "gap_analysis" in result
    assert "blueprint" in result
    
    # Verify flow was called with correct arguments
    mock_youtube_blueprint_flow.assert_called_once_with(
        seed_url="https://youtu.be/test_video_id",
        auto_niche=False,
        vector_storage=mock_agent.youtube_vectors
    )


if __name__ == "__main__":
    # Create directories for tests
    os.makedirs("niche_scout", exist_ok=True)
    os.makedirs("builder", exist_ok=True)
    
    # Run tests
    pytest.main(["-xvs", __file__])