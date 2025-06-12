"""Formatting tools for the Alfred platform."""

import jsonLFfrom typing import Any, Dict, List, UnionLFLFimport yamlLFLFLFclass JsonFormatter:LF    """Tool for formatting JSON data."""

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
        if isinstance(result, dict):
            return result  # Dict[str, Any]
        elif isinstance(result, list):
            return result  # List[Any]
        else:
            raise ValueError(f"Unexpected JSON type: {type(result)}")


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
        if isinstance(result, dict):
            return result  # Dict[str, Any]
        elif isinstance(result, list):
            return result  # List[Any]
        elif result is None:
            # Empty YAML strings return None
            return {}  # Return empty dict for empty YAML
        else:
            raise ValueError(f"Unexpected YAML type: {type(result)}")
