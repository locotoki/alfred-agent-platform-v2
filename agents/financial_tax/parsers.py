"""Custom parsers for financial tax agent API compatibility."""

import json

from langchain.output_parsers import PydanticOutputParser as BasePydanticOutputParser
# No BaseModel required here


class PydanticOutputParser(BasePydanticOutputParser):
    """Compatibility wrapper for LangChain Pydantic v2 output parser."""

    def get_format_instructions(self) -> str:
        """Return the format instructions for the JSON output.

        Returns:
            The format instructions for the JSON output.
        """
        schema = self.pydantic_object.model_json_schema()

        # Format the schema as output instructions
        schema_str = str(schema)
        return (
            f"The output should be formatted as a JSON instance that conforms to "
            f"the JSON schema below.\n\n"
            f"Here is the output schema:\n{schema_str}\n"
        )

    def parse(self, text: str):
        """Parse the output text into a Pydantic object.

        Args:
            text: The text to parse into a Pydantic object.

        Returns:
            A Pydantic object.
        """
        # Clean and parse the text
        cleaned_text = text.strip()
        # Try to find JSON in the text
        if not cleaned_text.startswith("{"):
            # Find the first { character
            start_idx = cleaned_text.find("{")
            if start_idx != -1:
                cleaned_text = cleaned_text[start_idx:]
            # Find the last } character
            end_idx = cleaned_text.rfind("}")
            if end_idx != -1:
                cleaned_text = cleaned_text[: end_idx + 1]

        try:
            json_object = json.loads(cleaned_text)
            return self.pydantic_object(**json_object)
        except (json.JSONDecodeError, TypeError) as e:
            raise ValueError(f"Failed to parse output: {cleaned_text}") from e
