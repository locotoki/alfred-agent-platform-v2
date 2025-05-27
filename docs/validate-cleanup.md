# Validate Cleanup Tracker 🗂️ *(Draft)*

> Issue #441 — eliminate template code & mypy red marks before GA.

## Ruff Auto-fix Summary
Ruff `--fix` run on $(date).

## Current mypy Failures
\`\`\`text
$(cat mypy-failures.txt)
\`\`\`

### TODO
- [ ] Triage each mypy error above.
- [ ] Remove unused template code.
- [ ] Rerun `mypy .` until clean.
