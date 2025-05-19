#!/bin/bash
# Install git hooks for the project

set -e

HOOK_DIR=$(git rev-parse --git-dir)/hooks
SCRIPT_DIR=$(dirname "$0")
PROJECT_ROOT=$(git rev-parse --show-toplevel)

# Create symbolic link to pre-commit-healthcheck in hooks directory if it doesn't exist
if [ ! -f "$HOOK_DIR/pre-commit" ]; then
  echo "Creating pre-commit hook..."
  cat > "$HOOK_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Main pre-commit hook that calls individual hook scripts

# Load hook execution environment
git_root=$(git rev-parse --show-toplevel)
echo -e "\033[1;33mRunning pre-commit checks...\033[0m"

# Execute individual hook scripts
for hook in "$git_root/.git/hooks/pre-commit-"*; do
  if [ -x "$hook" ]; then
    "$hook" "$@"
    RESULT=$?
    if [ $RESULT -ne 0 ]; then
      exit $RESULT
    fi
  fi
done

echo -e "\033[0;32mAll pre-commit checks passed.\033[0m"
exit 0
EOF
  chmod +x "$HOOK_DIR/pre-commit"
fi

# Install health check hook
if [ ! -f "$HOOK_DIR/pre-commit-healthcheck" ]; then
  echo "Installing healthcheck pre-commit hook..."
  cat > "$HOOK_DIR/pre-commit-healthcheck" << 'EOF'
#!/bin/bash
# Pre-commit hook to enforce health check standard in Dockerfiles

for df in $(git diff --cached --name-only | grep 'Dockerfile'); do
  if grep -q 'FROM ' "$df" && ! grep -q 'FROM .*healthcheck.* AS healthcheck' "$df"; then
    echo -e "\033[31m❌ $df missing healthcheck Stage-0\033[0m"
    echo -e "\033[33mPlease add the following at the top of your Dockerfile:\033[0m"
    echo -e "\033[32mFROM alfred/healthcheck:0.4.0 AS healthcheck\033[0m"
    echo -e "\033[33mAnd copy it into your main image:\033[0m"
    echo -e "\033[32mCOPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck\033[0m"
    echo -e "\033[32mRUN chmod +x /usr/local/bin/healthcheck\033[0m"
    exit 1
  fi

  if ! grep -q 'EXPOSE.*9091' "$df"; then
    echo -e "\033[31m❌ $df missing EXPOSE 9091 directive for metrics\033[0m"
    echo -e "\033[33mPlease add the following to your Dockerfile:\033[0m"
    echo -e "\033[32mEXPOSE 9091\033[0m"
    exit 1
  fi
done

# Check if docker-compose.yml was changed
if git diff --cached --name-only | grep -q 'docker-compose.yml'; then
  if git diff --cached docker-compose.yml | grep -E '^\+.*healthcheck:' | grep -v 'curl.*health'; then
    echo -e "\033[31m❌ docker-compose.yml may be using non-standard health check\033[0m"
    echo -e "\033[33mPlease use the following format for health checks:\033[0m"
    echo -e "\033[32mhealthcheck:\n  test: [\"CMD\", \"curl\", \"-f\", \"http://localhost:<PORT>/health\"]\n  <<: *basic-health-check\033[0m"
    exit 1
  fi
fi

exit 0
EOF
  chmod +x "$HOOK_DIR/pre-commit-healthcheck"
fi

# Install pre-commit tool and hooks
if [ -f "$PROJECT_ROOT/.pre-commit-config.yaml" ]; then
  echo "Installing pre-commit and hooks..."
  pip install pre-commit || python -m pip install pre-commit || python3 -m pip install pre-commit
  cd "$PROJECT_ROOT" && pre-commit install
fi

echo "Git hooks installed successfully."
