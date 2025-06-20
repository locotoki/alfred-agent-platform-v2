from architect_app import _messages_to_markdown


def test_markdown_export():
    msgs = [
        {"role": "user", "content": "Hi"},
        {"role": "assistant", "content": "Hello"},
    ]
    md = _messages_to_markdown(msgs)
    assert "# Architect Chat Export" in md
    assert "## User" in md and "## Assistant" in md