"""Protocol interfaces for alfred.slack module.

This module defines the abstract interfaces used throughout the alfred.slack
subsystem for Slack bot integration and messaging.
"""

from abc import abstractmethod
from typing import Any, Callable, Dict, List, Optional, Protocol


class SlackClient(Protocol):
    """Protocol for Slack API client interactions."""

    @abstractmethod
    async def send_message(
        self, channel: str, text: str, blocks: Optional[List[Dict[str, Any]]] = None
    ) -> Dict[str, Any]:
        """Send a message to a Slack channel.

        Args:
            channel: Channel ID or name.
            text: Plain text message.
            blocks: Optional rich block elements.

        Returns:
            Response from Slack API.
        """
        ...

    @abstractmethod
    async def update_message(
        self,
        channel: str,
        timestamp: str,
        text: str,
        blocks: Optional[List[Dict[str, Any]]] = None,
    ) -> Dict[str, Any]:
        """Update an existing message.

        Args:
            channel: Channel ID or name.
            timestamp: Message timestamp.
            text: Updated plain text.
            blocks: Optional updated block elements.

        Returns:
            Response from Slack API.
        """
        ...

    @abstractmethod
    async def get_user_info(self, user_id: str) -> Dict[str, Any]:
        """Get information about a user.

        Args:
            user_id: Slack user ID.

        Returns:
            User information dictionary.
        """
        ...


class CommandHandler(Protocol):
    """Protocol for slash command handlers."""

    @abstractmethod
    def handle_command(
        self,
        command: Dict[str, Any],
        ack: Callable[[], None],
        say: Callable[[str], None],
    ) -> None:
        """Handle a slash command.

        Args:
            command: Command payload from Slack.
            ack: Acknowledgment function.
            say: Message sending function.
        """
        ...

    @abstractmethod
    def get_command_help(self) -> str:
        """Get help text for this command.

        Returns:
            Help text string.
        """
        ...


class EventListener(Protocol):
    """Protocol for Slack event listeners."""

    @abstractmethod
    def handle_event(self, event: Dict[str, Any]) -> None:
        """Handle a Slack event.

        Args:
            event: Event payload from Slack.
        """
        ...

    @abstractmethod
    def get_event_types(self) -> List[str]:
        """Get list of event types this listener handles.

        Returns:
            List of event type strings.
        """
        ...


class DiagnosticsBot(Protocol):
    """Protocol for the Slack diagnostics bot."""

    @abstractmethod
    async def check_health(self, services: List[str]) -> Dict[str, bool]:
        """Check health of specified services.

        Args:
            services: List of service names to check.

        Returns:
            Dictionary mapping service names to health status.
        """
        ...

    @abstractmethod
    def generate_grafana_link(self, service_name: str, metric_type: str) -> str:
        """Generate Grafana link for service metrics.

        Args:
            service_name: Name of the service.
            metric_type: Type of metric to display.

        Returns:
            Grafana URL.
        """
        ...

    @abstractmethod
    def format_health_table(self, health_data: Dict[str, bool]) -> str:
        """Format health data as a table.

        Args:
            health_data: Dictionary of service health status.

        Returns:
            Formatted table string.
        """
        ...
