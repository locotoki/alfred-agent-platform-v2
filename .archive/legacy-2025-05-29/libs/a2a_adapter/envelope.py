from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import uuid4

from pydantic import BaseModel, Field


class Artifact(BaseModel):
    key: str
    uri: str
    mime_type: Optional[str] = None
    description: Optional[str] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)


class A2AEnvelope(BaseModel):
    schema_version: str = "0.4"
    task_id: str = Field(default_factory=lambda: str(uuid4()))
    intent: str
    role: str = "assistant"
    content: Dict[str, Any] = Field(default_factory=dict)
    artifacts: List[Artifact] = Field(default_factory=list)
    trace_id: str = Field(default_factory=lambda: str(uuid4()))
    correlation_id: Optional[str] = None
    timestamp: str = Field(default_factory=lambda: datetime.utcnow().isoformat() + "Z")
    metadata: Dict[str, Any] = Field(default_factory=dict)
    priority: int = Field(default=1, ge=1, le=5)
    timeout_seconds: int = Field(default=300, ge=1, le=3600)

    def to_pubsub_message(self) -> Dict[str, Any]:
        """Convert envelope to Pub/Sub message format"""
        return {
            "data": self.json(),
            "attributes": {
                "intent": self.intent,
                "priority": str(self.priority),
                "trace_id": self.trace_id,
            },
        }

    @classmethod
    def from_pubsub_message(cls, message: Dict[str, Any]) -> "A2AEnvelope":
        """Create envelope from Pub/Sub message"""
        data = message.get("data", "{}")
        if isinstance(data, bytes):
            data = data.decode("utf-8")
        return cls.parse_raw(data)
