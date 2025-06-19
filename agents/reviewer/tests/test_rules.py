import re, reviewer.entrypoint as R
def test_rule_regex():
    ok = "Some text\nprd-id: PRD-2025-13\nsomething\n task-id: 041"
    bad = "missing ids"
    pat = R.RULES["require_ids"]["pattern"]
    assert re.search(pat, ok, re.I|re.S)
    assert not re.search(pat, bad, re.I|re.S)