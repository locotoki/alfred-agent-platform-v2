"""HubSpot mock client – exposes Client class."""

from .client import Client


class MockModels:
    """Mock models module to avoid circular import."""

    class Contact:
        """Simple Contact model for testing."""

        def __init__(self, **kwargs):
            self.email = kwargs.get("email")
            self.first_name = kwargs.get("first_name")
            self.last_name = kwargs.get("last_name")

        def to_dict(self):
            return {"email": self.email, "first_name": self.first_name, "last_name": self.last_name}


# Create a models object with Contact as an attribute
models = MockModels()

__all__ = ["Client", "models"]
