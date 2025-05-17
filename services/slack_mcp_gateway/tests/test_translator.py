"""
Tests for the translator module.
"""

import uuid
from datetime import datetime
import json
import re

import pytest
import jsonschema

from slack_mcp_gateway import translator


# Mock Slack command payload
@pytest.fixture
def slack_command_payload():
    return {
        "token": "gIkuvaNzQIHg97ATvDxqgjtO",  # This would be a verification token in real usage
        "team_id": "T0001",
        "team_domain": "example",
        "channel_id": "C123456",
        "channel_name": "test-channel",
        "user_id": "U123456",
        "user_name": "test-user",
        "command": "/ping",
        "text": "hello world",
        "response_url": "https://hooks.slack.com/commands/T0001/12345/67890",
        "trigger_id": "13345224609.738474920.8088930838d88f008e0",
    }


# Task request schema for validation
@pytest.fixture
def task_request_schema():
    return {
        "type": "object",
        "required": ["tenant_id", "request_id", "user", "timestamp", "command", "task"],
        "properties": {
            "tenant_id": {"type": "string"},
            "request_id": {"type": "string", "format": "uuid"},
            "user": {"type": "string"},
            "timestamp": {"type": "string", "format": "date-time"},
            "command": {
                "type": "object",
                "required": ["name", "text", "channel_id", "response_url"],
                "properties": {
                    "name": {"type": "string"},
                    "text": {"type": "string"},
                    "channel_id": {"type": "string"},
                    "response_url": {"type": "string"},
                },
            },
            "task": {
                "type": "object",
                "required": ["agent", "action", "target"],
                "properties": {
                    "agent": {"type": "string"},
                    "action": {"type": "string"},
                    "target": {"type": "string"},
                },
            },
        },
    }


def test_build_task_request_structure(slack_command_payload, task_request_schema):
    """Test that the task request has the correct structure."""
    # Call the function to build a task request
    task_request = translator.build_task_request(slack_command_payload)

    # Basic structure assertions
    assert isinstance(task_request, dict)
    assert "tenant_id" in task_request
    assert "request_id" in task_request
    assert "user" in task_request
    assert "timestamp" in task_request
    assert "command" in task_request
    assert "task" in task_request

    # Validate against the schema
    jsonschema.validate(instance=task_request, schema=task_request_schema)


def test_build_task_request_field_values(slack_command_payload):
    """Test that the field values are correctly mapped from the input payload."""
    task_request = translator.build_task_request(slack_command_payload)

    # Check field mappings
    assert task_request["tenant_id"] == slack_command_payload["team_id"]
    assert task_request["user"] == slack_command_payload["user_id"]

    # Command section
    assert task_request["command"]["name"] == "ping"  # Removed leading slash
    assert task_request["command"]["text"] == slack_command_payload["text"]
    assert task_request["command"]["channel_id"] == slack_command_payload["channel_id"]
    assert task_request["command"]["response_url"] == slack_command_payload["response_url"]

    # Task section - should use infra.echo agent as the default
    assert task_request["task"]["agent"] == "infra.echo"
    assert task_request["task"]["action"] == "respond"
    assert task_request["task"]["target"] == slack_command_payload["text"]


def test_build_task_request_uuid_format(slack_command_payload):
    """Test that the request_id is a valid UUID."""
    task_request = translator.build_task_request(slack_command_payload)

    # Validate UUID format
    uuid_obj = uuid.UUID(task_request["request_id"])
    assert str(uuid_obj) == task_request["request_id"]


def test_build_task_request_timestamp_format(slack_command_payload):
    """Test that the timestamp is in the correct ISO format with Z suffix."""
    task_request = translator.build_task_request(slack_command_payload)

    # Validate ISO 8601 format with Z suffix
    iso_format_regex = r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$"
    assert re.match(iso_format_regex, task_request["timestamp"])

    # Should be parseable as a datetime
    datetime.fromisoformat(task_request["timestamp"].replace("Z", "+00:00"))


def test_build_task_request_empty_text(slack_command_payload):
    """Test handling of empty command text."""
    # Modify payload to have empty text
    modified_payload = slack_command_payload.copy()
    modified_payload["text"] = ""

    task_request = translator.build_task_request(modified_payload)

    # Should default to "ping" when text is empty
    assert task_request["task"]["target"] == "ping"
