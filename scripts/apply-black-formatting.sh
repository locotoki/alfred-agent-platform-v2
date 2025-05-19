#!/bin/bash
# Script to apply black formatting to the codebase
# Applies Black formatting to all Python files in the codebase

set -e

# Ensure we're in the repo root
cd "$(git rev-parse --show-toplevel)" || exit 1

BLACK_VERSION="24.1.1"
BRANCH_NAME="style/apply-black-format"
COMMIT_MESSAGE="style: Apply Black formatting to Python files"

# Parse command line arguments
AUTO_COMMIT=false
AUTO_PUSH=false
TARGET_BRANCH=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --commit)
      AUTO_COMMIT=true
      shift
      ;;
    --push)
      AUTO_COMMIT=true
      AUTO_PUSH=true
      shift
      ;;
    --branch)
      TARGET_BRANCH="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --commit            Automatically commit changes"
      echo "  --push              Automatically commit and push changes"
      echo "  --branch BRANCH     Create a new branch for formatting changes (default: $BRANCH_NAME)"
      echo "  --help              Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "Applying Black formatting to Python files..."

# Ensure we have the right version of Black
if ! pip list | grep -q "black.*$BLACK_VERSION"; then
  echo "Installing Black $BLACK_VERSION..."
  pip install black==$BLACK_VERSION || python -m pip install black==$BLACK_VERSION || python3 -m pip install black==$BLACK_VERSION
fi

# Get current branch for later
CURRENT_BRANCH=$(git branch --show-current)

# Create a new branch if requested
if [[ -n "$TARGET_BRANCH" && "$AUTO_COMMIT" == "true" ]]; then
  echo "Creating branch $TARGET_BRANCH..."
  git checkout -b "$TARGET_BRANCH"
fi

# Apply Black formatting
echo "Running Black formatter on Python files..."
black --exclude "(youtube-test-env/|migrations/|node_modules/|\.git/|\.mypy_cache/|\.env/|\.venv/|env/|venv/|\.ipynb/)" .

echo "Black formatting complete!"
echo "Formatted with Black version $BLACK_VERSION"

# Check if there are changes
if git diff --quiet -- '*.py'; then
  echo "No changes made. All Python files are already properly formatted."
  # Return to original branch if we switched
  if [[ -n "$TARGET_BRANCH" && "$AUTO_COMMIT" == "true" ]]; then
    git checkout "$CURRENT_BRANCH"
  fi
else
  echo "Files have been formatted. Please review the changes."

  if [[ "$AUTO_COMMIT" == "true" ]]; then
    echo "Adding changes to git..."
    git add -u "*.py"

    echo "Committing changes..."
    git commit -m "$COMMIT_MESSAGE"

    if [[ "$AUTO_PUSH" == "true" ]]; then
      echo "Pushing changes..."
      git push origin "$(git branch --show-current)"
      echo "Changes pushed successfully."
    else
      echo "Changes committed successfully. Use 'git push' to push them to the remote repository."
    fi
  else
    echo "Use 'git diff -- \"*.py\"' to see the formatting changes."
    echo "Use 'git add -u \"*.py\"' to stage the changes."
    echo "Use 'git commit -m \"$COMMIT_MESSAGE\"' to commit the changes."
  fi
fi

echo "Done!"
