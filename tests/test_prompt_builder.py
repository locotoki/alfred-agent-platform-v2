from common.prompt_builder import build_prompt, _token_len, MAX_TOKENS
def test_cap():
    systems = ["sys "*3000]*5  # huge chunks
    out = build_prompt(systems, "hello")
    assert _token_len(out) <= MAX_TOKENS
def test_order_preserved():
    # Create many snippets that together exceed MAX_TOKENS (but each under CHUNK_LIMIT)
    systems = ["A" * 500] * 50 + ["B" * 500] * 50 + ["C" * 500] * 50  # 150 snippets of 500 chars each
    prompt = build_prompt(systems, "Q")
    lines = prompt.splitlines()
    # Since we exceed MAX_TOKENS, the first (oldest) snippets 'A' should be dropped
    # Check that no line starts with 'A' (all A's should be dropped)
    a_lines = [line for line in lines if line.startswith("A")]
    assert len(a_lines) == 0, f"Expected all 'A' lines to be dropped, but found {len(a_lines)} A lines"