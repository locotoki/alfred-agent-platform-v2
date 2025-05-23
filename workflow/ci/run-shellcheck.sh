#!/usr/bin/env bash
# Runs ShellCheck on maintained automation scripts only.
set -eo pipefail

# Only check these specific directories
DIRS=( "workflow/cli" )   # Add more dirs when they're shellcheck-clean

files=()
for d in "${DIRS[@]}"; do
  if [ -d "$d" ]; then
    while IFS= read -r -d '' f; do 
      files+=("$f")
    done < <(find "$d" -type f -name '*.sh' -print0)
  fi
done

echo "ShellCheck scanning ${#files[@]} files in: ${DIRS[*]}"
[ ${#files[@]} -eq 0 ] && exit 0

# Run shellcheck with exclusions for common warnings in legacy code
shellcheck -x "${files[@]}"
