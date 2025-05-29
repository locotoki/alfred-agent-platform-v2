#!/bin/bash
# Prevent root directory sprawl

set -e

# Allowed files in root (customize as needed)
ALLOWED_ROOT_FILES=(
  "README.md"
  "CHANGELOG.md"
  "CLEANUP-STRATEGY.md"
  "LICENSE"
  "Makefile"
  "VERSION"
  ".gitignore"
  ".gitattributes"
  ".dockerignore"
  ".editorconfig"
  ".env"
  ".env.example"
  ".flake8"
  ".isort.cfg"
  ".coveragerc"
  ".pre-commit-config.yaml"
  ".gitleaksignore"
  ".licence_waivers"
  ".mypy-baseline.txt"
  "docker-compose.yml"
  "docker-compose.*.yml"
  "pyproject.toml"
  "poetry.lock"
  "requirements.txt"
  "package.json"
  "package-lock.json"
  "go.mod"
  "go.sum"
  "alembic.ini"
  "mypy.ini"
  "pytest.ini"
  "pytest-ci.ini"
  "setup.py"
  "setup.cfg"
  "Dockerfile"
  ".dockerignore"
  "status.json"
  "images.lock"
  "services.yaml"
  "trivy.yaml"
)

# Function to check if file is allowed
is_allowed() {
  local file="$1"
  for allowed in "${ALLOWED_ROOT_FILES[@]}"; do
    # Handle wildcards like docker-compose.*.yml
    if [[ "$allowed" == *"*"* ]]; then
      if [[ "$file" == $allowed ]]; then
        return 0
      fi
    elif [[ "$file" == "$allowed" ]]; then
      return 0
    fi
  done
  return 1
}

# Track violations
violations=0

# Check markdown files
for file in *.md; do
  if [[ -f "$file" ]] && ! is_allowed "$file"; then
    echo "❌ Unauthorized markdown in root: $file"
    echo "   → Move to docs/"
    ((violations++))
  fi
done

# Check text files
for file in *.txt; do
  if [[ -f "$file" ]] && ! is_allowed "$file"; then
    echo "❌ Unauthorized text file in root: $file"
    echo "   → Move to appropriate directory"
    ((violations++))
  fi
done

# Check log files
for file in *.log; do
  if [[ -f "$file" ]]; then
    echo "❌ Log file in root: $file"
    echo "   → Logs should not be committed"
    ((violations++))
  fi
done

# Check shell scripts
for file in *.sh; do
  if [[ -f "$file" ]] && ! is_allowed "$file"; then
    echo "❌ Script in root: $file"
    echo "   → Move to scripts/"
    ((violations++))
  fi
done

if [ $violations -gt 0 ]; then
  echo ""
  echo "Total violations: $violations"
  echo "Please move files to their appropriate directories."
  exit 1
fi

echo "✅ Root directory hygiene check passed"
exit 0