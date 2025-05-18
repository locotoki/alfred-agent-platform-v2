#!/bin/bash
# Reset files unrelated to current sprint work

cd /home/locotoki/projects/alfred-agent-platform-v2

# First, show what we'll keep
echo "Files to KEEP (related to current work):"
git status --porcelain | grep -E "(backend/alfred/(ml|search)|tests/backend/(ml|search)|benchmark|SPRINT|requirements)" | wc -l

# Reset everything in backup directories
echo "Resetting backup directories..."
git checkout -- backup/

# Reset old UI migration files
echo "Resetting old UI files..."
git checkout -- UI-*.md

# Reset old deployment/phase files
echo "Resetting old deployment files..."
git checkout -- DEPLOYMENT-*.md GA-*.md PHASE-*.md

# Reset everything in cleanup-temp
echo "Resetting cleanup-temp..."
git checkout -- cleanup-temp/

# Reset old services backups
echo "Resetting service backup files..."
git checkout -- services/**/*.bak-*

# Reset agent stubs
echo "Resetting agent stubs..."
git checkout -- agents/**/*.stub

# Show what's left
echo -e "\nRemaining uncommitted files:"
git status --short | wc -l
git status --short | grep -E "(backend/alfred|tests/backend|workflows|benchmark)" | head -20
