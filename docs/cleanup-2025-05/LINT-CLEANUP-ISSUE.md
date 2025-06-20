# Repo-wide Ruff/isort cleanup

Legacy agents fail Ruff import-order checks; clean up across repo.

## Background
During PR #55 development, the CI lint check failed on ~30 files with various linter violations (unused variables, trailing whitespace, etc). These issues pre-existed and were unrelated to the Slack MCP Gateway implementation.

## Issues Found
- `F841`: Local variables assigned but never used
- `W291`: Trailing whitespace
- `E402`: Module level import not at top of file
- `E712`: Incorrect boolean comparisons
- `E722`: Bare except statements
- `F541`: f-strings missing placeholders

## Files Affected
- agents/legal_compliance/chains.py
- agents/social_intel/flows/youtube_flows.py
- manual-niche-scout.py
- run-black-format.py
- scripts/test_youtube_agent.py
- scripts/test_youtube_api_key.py
- scripts/utils/cleanup_processed_messages.py
- scripts/utils/database_validation.py
- services/alfred-bot/app/main.py
- services/financial-tax/app/main.py
- services/legal-compliance/app/main.py
- services/architect-api/tests/unit/test_features.py
- tests/integration/test_exactly_once_processing.py

## Action Items
1. Run flake8 to identify all linter issues across the repository
2. Fix issues manually or use tools like `black` and `isort` for formatting
3. Update CI to enforce these standards going forward
4. Consider adding pre-commit hooks to catch these issues early

🤖 Generated with [Claude Code](https://claude.ai/code)
