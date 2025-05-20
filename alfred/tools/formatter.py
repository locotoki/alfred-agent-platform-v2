"""Formatting tools for the Alfred platform."""

import json
from typing import Any, Dict, List, Union

import yaml


class JsonFormatter:
    """Tool for formatting JSON data."""

    def __init__(self, indent: int = 2) -> None:
        """Initialize the JSON formatter.

        Args:
            indent: Number of spaces for indentation.
        """
        self.indent = indent

    def format(self, data: Union[Dict[str, Any], List[Any]]) -> str:
        """Format data as a JSON string.

        Args:
            data: The data to format.

        Returns:
            Formatted JSON string.
        """
        return json.dumps(data, indent=self.indent)

    def parse(self, text: str) -> Union[Dict[str, Any], List[Any]]:
        """Parse a JSON string into a Python object.

        Args:
            text: JSON string to parse.

        Returns:
            Parsed Python object.
        """
        result = json.loads(text)
        if isinstance(result, (dict, list)):
            return result
        raise ValueError(f"Expected dict or list, got {type(result).__name__}")


class YamlFormatter:
    """Tool for formatting YAML data."""

    def __init__(self) -> None:
        """Initialize the YAML formatter."""
        pass

    def format(self, data: Union[Dict[str, Any], List[Any]]) -> str:
        """Format data as a YAML string.

        Args:
            data: The data to format.

        Returns:
            Formatted YAML string.
        """
        return yaml.safe_dump(data, default_flow_style=False)

    def parse(self, text: str) -> Union[Dict[str, Any], List[Any]]:
        """Parse a YAML string into a Python object.

        Args:
            text: YAML string to parse.

        Returns:
            Parsed Python object.
        """
        result = yaml.safe_load(text)
        if isinstance(result, (dict, list)):
            return result
        if result is None:
            return {}  # Empty YAML document returns None, convert to empty dict
        raise ValueError(f"Expected dict or list, got {type(result).__name__}")
