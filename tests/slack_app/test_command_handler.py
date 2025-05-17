"""
Test the Slack app command handler functionality.
This test simulates a slash command payload and verifies the handler works correctly.
"""

import json
import os
import sys
from unittest.mock import MagicMock, call, patch

import pytest

# Import the application module
from services.slack_app.app import COMMAND_PREFIX, app, handle_alfred_command, handle_help_command


def test_command_registration():
    """Test that the command is registered correctly."""
    # Get all registered listeners
    listeners = app.listeners

    # Find slash command listeners
    command_listeners = [l for l in listeners if l.matcher.match_function_name == "match_event"]

    # Check if we have at least one command listener
    assert len(command_listeners) > 0, "No command listeners registered"

    # Print the command matchers for debugging
    for listener in command_listeners:
        print(f"Registered listener: {listener.matcher.__dict__}")

    # Check if our specific command is registered
    # Note: Slack Bolt expects command without the slash prefix
    command_name = COMMAND_PREFIX.lstrip("/")
    alfred_listeners = [
        l
        for l in command_listeners
        if hasattr(l.matcher, "command") and l.matcher.command == command_name
    ]

    # This assertion will fail if the command is registered WITH the slash
    assert len(alfred_listeners) > 0, f"Command '{command_name}' not registered correctly"


def test_alfred_command_handler():
    """Test the alfred command handler with a simulated payload."""
    # Create a mock ack function
    mock_ack = MagicMock()

    # Create a mock say function
    mock_say = MagicMock()

    # Create a simulated command payload
    command = {
        "command": "/alfred",
        "text": "help",
        "user_id": "U12345",
        "channel_id": "C12345",
        "response_url": "https://slack.com/response_url",
    }

    # Call the handler directly with our mocks
    handle_alfred_command(ack=mock_ack, command=command, say=mock_say)

    # Verify ack was called
    mock_ack.assert_called_once()

    # Verify say was called with the help text
    assert mock_say.call_count > 0, "say() was never called"

    # Inspect the message sent to say()
    help_message = mock_say.call_args[0][0]
    assert "Alfred Slack Bot Commands" in help_message, "Help message not sent"


def test_help_command_handler():
    """Test the help command handler directly."""
    # Create a mock say function
    mock_say = MagicMock()

    # Call the handler directly
    handle_help_command(say=mock_say)

    # Verify say was called with help text
    mock_say.assert_called_once()

    # Check the help message content
    help_message = mock_say.call_args[0][0]
    assert "Alfred Slack Bot Commands" in help_message
    assert "/alfred help" in help_message
    assert "/alfred status" in help_message


def test_empty_command_defaults_to_help():
    """Test that an empty command defaults to help."""
    # Create mock functions
    mock_ack = MagicMock()
    mock_say = MagicMock()

    # Create a command with empty text
    command = {
        "command": "/alfred",
        "text": "",  # Empty command text
        "user_id": "U12345",
        "channel_id": "C12345",
    }

    # Call the handler
    handle_alfred_command(ack=mock_ack, command=command, say=mock_say)

    # Verify ack was called
    mock_ack.assert_called_once()

    # Verify say was called with help text
    assert mock_say.call_count > 0
    help_message = mock_say.call_args[0][0]
    assert "Alfred Slack Bot Commands" in help_message


# Run this test if you suspect ack() timing issues
def test_ack_timing():
    """Test that ack() is called immediately."""
    import time

    # Times when actions occur
    timestamps = {"start": 0, "ack": 0, "say": 0}

    # Create a timing aware ack function
    def timing_ack():
        timestamps["ack"] = time.time()

    # Create a timing aware say function with a delay
    def timing_say(message):
        time.sleep(1)  # Simulate processing time
        timestamps["say"] = time.time()

    # Create a command
    command = {"command": "/alfred", "text": "help", "user_id": "U12345", "channel_id": "C12345"}

    # Call the handler and record the start time
    timestamps["start"] = time.time()
    handle_alfred_command(ack=timing_ack, command=command, say=timing_say)

    # Verify ack was called before say
    assert timestamps["ack"] > timestamps["start"], "ack() was never called"
    assert timestamps["say"] > timestamps["ack"], "say() was called before ack()"

    # Verify ack was called quickly (within 100ms)
    assert timestamps["ack"] - timestamps["start"] < 0.1, "ack() was not called quickly enough"
