#!/bin/bash
# Archive old files that keep getting modified but aren't actively used

# Create archive directory outside the project
ARCHIVE_DIR="/home/locotoki/alfred-archives-$(date +%Y%m%d)"
mkdir -p "$ARCHIVE_DIR"

echo "Archiving old files to: $ARCHIVE_DIR"

# Directories to move (not actively used)
DIRS_TO_ARCHIVE=(
    "backup"
    "backup-tmp"
    "cleanup-temp"
    "logs"
    "tmp"
    "venv"
    "node_modules"
    "docs/archive"
    "docs/staging-area"
    "services/**/*.bak-*"
)

# Create archive structure
for dir in "${DIRS_TO_ARCHIVE[@]}"; do
    if [ -d "$dir" ] || compgen -G "$dir" > /dev/null; then
        echo "Archiving: $dir"
        # Create parent directory structure in archive
        mkdir -p "$ARCHIVE_DIR/$(dirname "$dir")"
        # Move the directory/files
        mv $dir "$ARCHIVE_DIR/$(dirname "$dir")/" 2>/dev/null || true
    fi
done

# Archive old root-level markdown files that keep getting modified
OLD_MD_FILES=(
    "DEPLOYMENT-*.md"
    "UI-*.md"
    "PHASE-*.md"
    "GA-*.md"
    "PORT-*.md"
    "PR-*.md"
    "RCA-*.md"
)

mkdir -p "$ARCHIVE_DIR/old-docs"
for pattern in "${OLD_MD_FILES[@]}"; do
    if compgen -G "$pattern" > /dev/null; then
        echo "Archiving markdown files: $pattern"
        mv $pattern "$ARCHIVE_DIR/old-docs/" 2>/dev/null || true
    fi
done

# Create a restoration script
cat > "$ARCHIVE_DIR/restore-files.sh" << 'EOF'
#!/bin/bash
# Restore archived files back to the project

PROJECT_DIR="/home/locotoki/projects/alfred-agent-platform-v2"
ARCHIVE_DIR="$(dirname "$0")"

echo "Restoring files from $ARCHIVE_DIR to $PROJECT_DIR"

# Copy everything back (preserving structure)
cp -r "$ARCHIVE_DIR"/* "$PROJECT_DIR/" 2>/dev/null || true

echo "Files restored. You may need to:"
echo "1. Remove the restore script from the project"
echo "2. Run git status to see what was restored"
EOF

chmod +x "$ARCHIVE_DIR/restore-files.sh"

# Update .gitignore to ensure these don't come back
echo -e "\n# Archived directories (moved to $ARCHIVE_DIR)" >> .gitignore
echo "backup/" >> .gitignore
echo "backup-tmp/" >> .gitignore
echo "cleanup-temp/" >> .gitignore
echo "*.bak-*" >> .gitignore

echo "Archive complete!"
echo "Files moved to: $ARCHIVE_DIR"
echo "Added entries to .gitignore to prevent recreation"
echo "To restore files, run: $ARCHIVE_DIR/restore-files.sh"

# Show what's left
echo -e "\nRemaining project structure:"
find . -type d -name ".git" -prune -o -type d -print | grep -v "^\./\." | sort | head -20