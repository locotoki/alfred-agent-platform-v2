#!/bin/bash
# Preserve only Sprint 5 and ML work, reset everything else

cd /home/locotoki/projects/alfred-agent-platform-v2

# Create a list of files we want to keep
echo "Creating list of files to preserve..."
git status --porcelain | cut -c4- | grep -E "(backend/alfred/(ml|search)|tests/backend/(ml|search)|trainer.*benchmark|ranker.*benchmark|SPRINT.*\.md|docs/phase8/SPRINT|docs/sprint5|requirements.txt$|pyproject.toml$)" > files-to-keep.txt

# Reset everything
echo "Resetting all changes..."
git checkout -- .

# Re-apply changes only to files we want to keep
echo "Re-applying changes to preserved files..."
while IFS= read -r file; do
    if [ -f "$file" ]; then
        git checkout HEAD~1 -- "$file" 2>/dev/null || true
    fi
done < files-to-keep.txt

# Clean up
rm files-to-keep.txt

# Show final state
echo -e "\nFinal state - remaining uncommitted files:"
git status --short | wc -l
echo -e "\nRelevant ML/Sprint files:"
git status --short | grep -E "(backend/alfred|tests/backend|benchmark|sprint)" | sort