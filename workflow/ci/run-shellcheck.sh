#!/usr/bin/env bash
# Runs ShellCheck on maintained automation scripts only.
set -eo pipefail
DIRS=( "workflow/cli" "scripts" )   # extend when new dirs are lint-ready
files=()
for d in "${DIRS[@]}"; do
  while IFS= read -r -d '' f; do files+=("$f"); done < <(find "$d" -type f -name '*.sh' -print0)
done
echo "ShellCheck scanning ${#files[@]} files…"
[ ${#files[@]} -eq 0 ] && exit 0
shellcheck -x "${files[@]}"
