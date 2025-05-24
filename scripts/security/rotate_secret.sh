#\!/usr/bin/env bash
# Usage: ./rotate_secret.sh <secret_name>
set -euo pipefail
[[ $# -eq 1 ]] || { echo "need secret name"; exit 1; }
SECRET=$1
NEW=$(openssl rand -base64 32)
echo "$NEW" > "secrets/${SECRET}.txt"
chmod 600 "secrets/${SECRET}.txt"
echo "New value for $SECRET stored in secrets/${SECRET}.txt"
