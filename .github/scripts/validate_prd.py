#!/usr/bin/env python3
"""
Simple PRD front-matter & structure validator.
Fails (exit 1) if:
  • required front-matter keys are missing
  • 'Acceptance Tasks' list not present or empty
"""
import sys, yaml, pathlib, re

def load_prd(path):
    txt = pathlib.Path(path).read_text()
    m = re.match(r'^---\n(.*?)\n---\n(.*)', txt, re.S)
    if not m:
        sys.exit(f"{path}: missing YAML front-matter")
    meta = yaml.safe_load(m.group(1))
    body = m.group(2)
    return meta, body

def main():
    ok = True
    required = {"id", "feature", "owner", "priority", "success_criteria"}
    for prd in pathlib.Path("docs/prd").rglob("*.md"):
        meta, body = load_prd(prd)
        missing = required - meta.keys()
        if missing:
            print(f"❌ {prd}: missing keys {sorted(missing)}")
            ok = False
        if not re.search(r'^## Acceptance Tasks\n- \[ \]', body, re.M):
            print(f"❌ {prd}: missing 'Acceptance Tasks' checklist")
            ok = False
    if not ok:
        sys.exit(1)
    print("✅ PRD validation passed.")

if __name__ == "__main__":
    main()