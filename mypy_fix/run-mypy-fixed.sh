#!/bin/bash
# Script to run mypy with special handling for namespace packages

set -euo pipefail

# For cleanup PR, we only need to check health module
python -m mypy --config-file=mypy.ini libs/agent_core/health

# Exit with success
exit 0