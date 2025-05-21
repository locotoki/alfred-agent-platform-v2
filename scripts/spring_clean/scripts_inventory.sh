#!/bin/bash
# scripts_inventory.sh - List all repo files for Spring-Clean inventory
#
# This script lists all files in the repository, excluding .git, .gitignore patterns,
# and other standard excludes for classification during the Spring-Clean initiative.

set -euo pipefail

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

# Output directory
INVENTORY_DIR="${PROJECT_ROOT}/arch/spring_clean"
mkdir -p "${INVENTORY_DIR}"

# Temporary output file for raw listing
RAW_LIST="${INVENTORY_DIR}/raw_file_list.txt"

# Use git ls-files to get all tracked files
echo "Generating list of all tracked files..."
git ls-files > "${RAW_LIST}"

# Also include untracked files that aren't ignored
echo "Adding untracked files (that aren't gitignored)..."
git ls-files --others --exclude-standard >> "${RAW_LIST}"

# Sort and remove duplicates
sort -u "${RAW_LIST}" -o "${RAW_LIST}"

# Count total files
TOTAL_FILES=$(wc -l < "${RAW_LIST}")
echo "Found ${TOTAL_FILES} files to classify."

# Output to stdout for further processing
cat "${RAW_LIST}"

echo "Raw file list saved to ${RAW_LIST}"
echo "Use this list to classify files as USED or ORPHAN in inventory.csv"
