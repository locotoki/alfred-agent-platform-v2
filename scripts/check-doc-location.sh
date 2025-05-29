#!/bin/bash
# Check that documentation is in the correct location

set -e

# Get the file path passed by pre-commit
FILE="$1"

# Skip if file is already in docs/
if [[ "$FILE" == docs/* ]]; then
  exit 0
fi

# Skip if file is an allowed root documentation file
ALLOWED_ROOT_DOCS=(
  "README.md"
  "CHANGELOG.md"
  "LICENSE"
  "CONTRIBUTING.md"
  "SECURITY.md"
  "CODE_OF_CONDUCT.md"
)

filename=$(basename "$FILE")
for allowed in "${ALLOWED_ROOT_DOCS[@]}"; do
  if [[ "$filename" == "$allowed" ]]; then
    exit 0
  fi
done

# Skip if file is in a service directory (services have their own READMEs)
if [[ "$FILE" == services/*/README.md ]] || [[ "$FILE" == */README.md ]]; then
  exit 0
fi

# If we get here, the markdown file is in the wrong location
echo "❌ Documentation file in wrong location: $FILE"
echo ""
echo "Documentation should be organized as follows:"
echo "  - Architecture docs → docs/architecture/"
echo "  - API docs → docs/api/"
echo "  - Guides → docs/guides/"
echo "  - Operational docs → docs/operational/"
echo "  - Runbooks → docs/runbooks/"
echo "  - Service docs → docs/services/<service-name>/"
echo ""
echo "Only these files are allowed in root:"
echo "  README.md, CHANGELOG.md, LICENSE, CONTRIBUTING.md, SECURITY.md"

exit 1