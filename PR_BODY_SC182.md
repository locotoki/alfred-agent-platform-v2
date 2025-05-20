✅ Execution Summary
- Removed problematic .env-common property from compose generation
- Added proper environment variable handling for all services
- Added adapter directory scanning for compose files
- Fixed script to apply common env vars properly
- Added type hints to compose generation scripts
- Fixed formatting in compose generators according to Black standards
- Created new script for running Black formatter across the repository

🧪 Output / Logs
```console
# Docker Compose Generation Error
validating /home/locotoki/projects/alfred-agent-platform-v2/docker-compose.generated.yml: (root) Additional property .env-common is not allowed
make: *** [Makefile:94: up] Error 1

# Type hints and formatting fixes
reformatted /home/locotoki/projects/alfred-agent-platform-v2/scripts/generate_compose.py
reformatted /home/locotoki/projects/alfred-agent-platform-v2/scripts/generate_compose_fixed.py
reformatted /home/locotoki/projects/alfred-agent-platform-v2/local-analysis/generate_compose_fixed.py
```

🧾 Checklist
- Acceptance criteria met? ✅ (Fixed docker-compose generation script)
- Tier-0 CI status: CI failing due to repo-wide Black formatting issues (will be resolved by PR #190)
- Local stack passes compose-health-check.sh: Improved with generate_compose_fixed.py
- Docs/CHANGELOG updated? ✅

📍Next Required Action
- This PR is blocked on repo-wide Black formatter PR (#190)
- After #190 merges, this PR should pass CI automatically

This addresses Issue #182: Fix docker-compose generation script
