#\!/usr/bin/env bash
set -euo pipefail
generated=($(docker compose --profile core config --services  < /dev/null |  sort))
expected=($(yq '.services | keys | .[]' compose.yml | sort))
diff -u <(printf "%s\n" "${expected[@]}") <(printf "%s\n" "${generated[@]}")
