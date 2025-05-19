"""Protocol interfaces for alfred.ui module.

This module defines the abstract interfaces used throughout the alfred.ui
subsystem for user interface components and interactions.
"""

from abc import abstractmethod
from typing import Any, Dict, List, Optional, Protocol


class ChatInterface(Protocol):
    """Protocol for chat interface implementations."""

    @abstractmethod
    async def send_message(self, message: str, user_id: str) -> Dict[str, Any]:
        """Send a message in the chat.

        Args:
            message: Message content.
            user_id: User identifier.

        Returns:
            Response dictionary.
        """
        ...

    @abstractmethod
    async def get_conversation_history(self, user_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Get conversation history for a user.

        Args:
            user_id: User identifier.
            limit: Maximum number of messages to return.

        Returns:
            List of message dictionaries.
        """
        ...

    @abstractmethod
    def render_message(self, message: Dict[str, Any]) -> str:
        """Render a message for display.

        Args:
            message: Message dictionary.

        Returns:
            HTML or formatted string for display.
        """
        ...


class DashboardWidget(Protocol):
    """Protocol for dashboard widget components."""

    @abstractmethod
    def render(self) -> str:
        """Render the widget.

        Returns:
            HTML or component string.
        """
        ...

    @abstractmethod
    def update_data(self, data: Dict[str, Any]) -> None:
        """Update widget data.

        Args:
            data: New data for the widget.
        """
        ...

    @abstractmethod
    def get_config(self) -> Dict[str, Any]:
        """Get widget configuration.

        Returns:
            Configuration dictionary.
        """
        ...


class UITheme(Protocol):
    """Protocol for UI theming."""

    @abstractmethod
    def get_colors(self) -> Dict[str, str]:
        """Get theme colors.

        Returns:
            Dictionary of color mappings.
        """
        ...

    @abstractmethod
    def get_fonts(self) -> Dict[str, str]:
        """Get theme fonts.

        Returns:
            Dictionary of font mappings.
        """
        ...

    @abstractmethod
    def get_styles(self, component: str) -> Dict[str, Any]:
        """Get styles for a specific component.

        Args:
            component: Component name.

        Returns:
            Style dictionary.
        """
        ...


class FormValidator(Protocol):
    """Protocol for form validation."""

    @abstractmethod
    def validate_field(self, field_name: str, value: Any) -> tuple[bool, Optional[str]]:
        """Validate a single form field.

        Args:
            field_name: Name of the field.
            value: Field value.

        Returns:
            Tuple of (is_valid, error_message).
        """
        ...

    @abstractmethod
    def validate_form(self, form_data: Dict[str, Any]) -> Dict[str, str]:
        """Validate entire form.

        Args:
            form_data: Dictionary of form data.

        Returns:
            Dictionary of field_name to error_message.
        """
        ...


class NotificationManager(Protocol):
    """Protocol for UI notifications."""

    @abstractmethod
    def show_notification(self, message: str, type: str = "info", duration: int = 5000) -> str:
        """Show a notification.

        Args:
            message: Notification message.
            type: Notification type (info, success, warning, error).
            duration: Duration in milliseconds.

        Returns:
            Notification ID.
        """
        ...

    @abstractmethod
    def hide_notification(self, notification_id: str) -> None:
        """Hide a notification.

        Args:
            notification_id: ID of notification to hide.
        """
        ...

    @abstractmethod
    def clear_all_notifications(self) -> None:
        """Clear all notifications."""
        ...


class SessionManager(Protocol):
    """Protocol for user session management."""

    @abstractmethod
    def create_session(self, user_id: str, session_data: Dict[str, Any]) -> str:
        """Create a new user session.

        Args:
            user_id: User identifier.
            session_data: Initial session data.

        Returns:
            Session ID.
        """
        ...

    @abstractmethod
    def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get session data.

        Args:
            session_id: Session identifier.

        Returns:
            Session data or None if not found.
        """
        ...

    @abstractmethod
    def update_session(self, session_id: str, updates: Dict[str, Any]) -> bool:
        """Update session data.

        Args:
            session_id: Session identifier.
            updates: Data updates.

        Returns:
            True if update was successful.
        """
        ...

    @abstractmethod
    def end_session(self, session_id: str) -> bool:
        """End a session.

        Args:
            session_id: Session identifier.

        Returns:
            True if session was ended successfully.
        """
        ...
