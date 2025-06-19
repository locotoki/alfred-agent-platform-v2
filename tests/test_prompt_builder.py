from common.prompt_builder import build_prompt, _token_len, MAX_TOKENS
def test_cap():
    systems = ["sys "*3000]*5  # huge chunks
    out = build_prompt(systems, "hello")
    assert _token_len(out) <= MAX_TOKENS
def test_order_preserved():
    sys = ["A","B","C"]
    prompt = build_prompt(sys, "Q")
    assert prompt.splitlines()[0].startswith("B")  # 'A' dropped first