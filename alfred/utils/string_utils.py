"""String utility functions for the Alfred platform."""

from typing import List


def truncate(text: str, max_length: int = 100, suffix: str = "...") -> str:
    """Truncate a string to a maximum length, appending a suffix if truncated.

    Args:
        text: The input string to truncate.
        max_length: Maximum allowed length of the output string.
        suffix: String to append if truncation occurs.

    Returns:
        The truncated string.
    """
    if len(text) <= max_length:
        return text
    return text[: max_length - len(suffix)] + suffix


def split_text(text: str, chunk_size: int = 1000, overlap: int = 200) -> List[str]:
    """Split text into chunks of specified size with overlap.

    Args:
        text: The input text to split.
        chunk_size: Maximum size of each chunk.
        overlap: Number of characters to overlap between chunks.

    Returns:
        List of text chunks.
    """
    if len(text) <= chunk_size:
        return [text]

    chunks: List[str] = []
    start = 0

    while start < len(text):
        end = min(start + chunk_size, len(text))

        # Try to find a good break point (newline or space)
        if end < len(text):
            # Look for newline first
            for i in range(end, max(end - 50, start), -1):
                if text[i] == "\n":
                    end = i + 1
                    break
            else:
                # No newline found, try for space
                for i in range(end, max(end - 50, start), -1):
                    if text[i] == " ":
                        end = i + 1
                        break

        # Add the chunk
        chunks.append(text[start:end])

        # Calculate next start position with overlap
        start = end - overlap if end < len(text) else len(text)

    return chunks
