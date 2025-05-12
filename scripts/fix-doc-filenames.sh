#!/bin/bash
# Script to fix documentation filenames by replacing spaces with hyphens 
# and normalizing special characters

# Set the base directory to search
BASE_DIR="/home/locotoki/projects/alfred-agent-platform-v2/docs"

# Create a log file
LOG_FILE="/home/locotoki/projects/alfred-agent-platform-v2/doc-rename-log.txt"
echo "Document Rename Log - $(date)" > "$LOG_FILE"
echo "====================================" >> "$LOG_FILE"

# Function to convert a filename to kebab-case
# Replaces spaces with hyphens, removes special characters, and converts to lowercase
kebab_case() {
    local filename="$1"
    # Strip Zone.Identifier suffixes
    filename="${filename%:Zone.Identifier}"
    # Replace spaces with hyphens
    filename="${filename// /-}"
    # Replace multiple hyphens with a single hyphen
    filename="${filename//--/-}"
    # Replace various Unicode dash characters with standard hyphen
    filename="${filename//—/-}" # em dash
    filename="${filename//–/-}" # en dash
    filename="${filename//‑/-}" # non-breaking hyphen
    # Replace other special characters
    filename="${filename//&/and}"
    filename="${filename//://}"
    filename="${filename//\?/}"
    filename="${filename//\!/}"
    filename="${filename//\#/}"
    filename="${filename//\*/}"
    # Remove any numeric ID suffixes like "1eab4fd21ff08080a6ebccdf693562f3"
    filename=$(echo "$filename" | sed -E 's/-[0-9a-f]{32}//g')
    # Trim hyphens from beginning and end
    filename="${filename#-}"
    filename="${filename%-}"
    # Convert to lowercase
    echo "${filename,,}"
}

# Process files with spaces in their names recursively
find "$BASE_DIR" -type f -name "* *" | while read -r file; do
    dir=$(dirname "$file")
    base=$(basename "$file")
    
    # Skip processing if it's a backup or temporary file
    if [[ "$base" == *"~"* || "$base" == *".bak"* || "$base" == *".tmp"* ]]; then
        continue
    fi
    
    # Create new filename
    new_base=$(kebab_case "$base")
    new_file="$dir/$new_base"
    
    # If the new filename is different from the old one
    if [ "$file" != "$new_file" ]; then
        # Check if target file already exists
        if [ -e "$new_file" ]; then
            echo "WARNING: Cannot rename '$file' to '$new_file' - destination exists" >> "$LOG_FILE"
        else
            # Perform the rename
            mv "$file" "$new_file"
            echo "Renamed: '$file' to '$new_file'" >> "$LOG_FILE"
        fi
    fi
done

# Process files with Unicode special characters
find "$BASE_DIR" -type f -name "*–*" -o -name "*—*" -o -name "*‑*" | while read -r file; do
    dir=$(dirname "$file")
    base=$(basename "$file")
    
    # Create new filename
    new_base=$(kebab_case "$base")
    new_file="$dir/$new_base"
    
    # If the new filename is different from the old one
    if [ "$file" != "$new_file" ]; then
        # Check if target file already exists
        if [ -e "$new_file" ]; then
            echo "WARNING: Cannot rename '$file' to '$new_file' - destination exists" >> "$LOG_FILE"
        else
            # Perform the rename
            mv "$file" "$new_file"
            echo "Renamed: '$file' to '$new_file'" >> "$LOG_FILE"
        fi
    fi
done

# Remove Windows Zone.Identifier files
find "$BASE_DIR" -type f -name "*:Zone.Identifier" | while read -r file; do
    rm "$file"
    echo "Removed Windows metadata file: '$file'" >> "$LOG_FILE"
done

echo "====================================" >> "$LOG_FILE"
echo "Rename operation completed - $(date)" >> "$LOG_FILE"
echo "Script execution complete. Check $LOG_FILE for details."