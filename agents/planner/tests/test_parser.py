from planner.planner_prd import parse_tasks
def test_parse_tasks():
    from pathlib import Path
    import tempfile
    tmp = Path("tmp_prd.md")
    tmp.write_text("""---
id: TEST
---

## Acceptance Tasks
- Task A
- Task B
""")
    tasks = parse_tasks(tmp)
    assert tasks == ["Task A","Task B"]
    tmp.unlink()  # cleanup