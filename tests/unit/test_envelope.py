import pytest
from datetime import datetime

from libs.a2a_adapter import A2AEnvelope, Artifact


def test_envelope_creation():
    """Test creating an A2A envelope."""
    envelope = A2AEnvelope(intent="TEST_INTENT", content={"message": "test"})

    assert envelope.schema_version == "0.4"
    assert envelope.intent == "TEST_INTENT"
    assert envelope.role == "assistant"
    assert isinstance(envelope.task_id, str)
    assert isinstance(envelope.trace_id, str)
    assert isinstance(envelope.timestamp, str)
    assert envelope.priority == 1


def test_envelope_serialization():
    """Test envelope serialization and deserialization."""
    original = A2AEnvelope(
        intent="TEST_INTENT",
        content={"message": "test"},
        artifacts=[Artifact(key="test", uri="s3://bucket/file.txt")],
    )

    # Serialize to Pub/Sub message
    pubsub_msg = original.to_pubsub_message()
    assert "data" in pubsub_msg
    assert "attributes" in pubsub_msg

    # Deserialize back
    recovered = A2AEnvelope.from_pubsub_message(pubsub_msg)

    assert recovered.intent == original.intent
    assert recovered.task_id == original.task_id
    assert recovered.content == original.content
    assert len(recovered.artifacts) == 1
    assert recovered.artifacts[0].key == "test"


def test_artifact_model():
    """Test Artifact model."""
    artifact = Artifact(
        key="report",
        uri="s3://reports/2024/analysis.pdf",
        mime_type="application/pdf",
        description="Analysis report",
    )

    assert artifact.key == "report"
    assert artifact.uri == "s3://reports/2024/analysis.pdf"
    assert artifact.mime_type == "application/pdf"
    assert artifact.description == "Analysis report"


def test_envelope_trace_id_and_correlation_id():
    """Test trace_id and correlation_id functionality."""
    # Test default behavior - trace_id is generated, correlation_id is None
    envelope1 = A2AEnvelope(intent="TEST")
    assert isinstance(envelope1.trace_id, str)
    assert len(envelope1.trace_id) > 0
    assert envelope1.correlation_id is None

    # Test with explicit correlation_id
    parent_task_id = "parent-123"
    envelope2 = A2AEnvelope(intent="TEST", correlation_id=parent_task_id)
    assert envelope2.correlation_id == parent_task_id

    # Test trace_id persistence in Pub/Sub message attributes
    pubsub_msg = envelope2.to_pubsub_message()
    assert pubsub_msg["attributes"]["trace_id"] == envelope2.trace_id

    # Test round-trip serialization preserves all IDs
    envelope3 = A2AEnvelope(
        intent="TEST", task_id="task-123", trace_id="trace-456", correlation_id="corr-789"
    )
    pubsub_msg3 = envelope3.to_pubsub_message()
    recovered = A2AEnvelope.from_pubsub_message(pubsub_msg3)

    assert recovered.task_id == envelope3.task_id
    assert recovered.trace_id == envelope3.trace_id
    assert recovered.correlation_id == envelope3.correlation_id


def test_envelope_schema_version_validation():
    """Test schema version handling."""
    envelope = A2AEnvelope(intent="TEST")
    assert envelope.schema_version == "0.4"

    # Test with explicit schema version
    envelope_custom = A2AEnvelope(intent="TEST", schema_version="0.5")
    assert envelope_custom.schema_version == "0.5"
