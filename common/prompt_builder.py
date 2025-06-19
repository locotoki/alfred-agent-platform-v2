"""
Build a prompt with hard 12k-token cap.
Assumes tiktoken-like .encode() method; falls back to len(str)//4.
"""

MAX_TOKENS = 12_000
CHUNK_LIMIT = 512   # each retrieved chunk max chars

def _token_len(text, encoder=None):
    if encoder:
        return len(encoder.encode(text))
    return int(len(text) / 4)  # heuristic

def build_prompt(system_snippets, user_query, encoder=None):
    """Assemble prompt: [system_snippets…, user query]. Each snippet cropped to CHUNK_LIMIT.
    Ensures total tokens ≤ MAX_TOKENS by dropping oldest snippets last."""
    sanitized = [s[:CHUNK_LIMIT] for s in system_snippets]
    prompt_parts = sanitized + [user_query]
    while _token_len("\n".join(prompt_parts), encoder) > MAX_TOKENS and len(prompt_parts) > 2:
        prompt_parts.pop(0)  # drop oldest system snippet
    return "\n".join(prompt_parts)