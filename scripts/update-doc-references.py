#!/usr/bin/env python3
"""
Script to update references in Markdown documents after renaming files.
This will scan all markdown files and update references to match the new kebab-case format.
"""

import os
import re
import sys
from pathlib import Path

# Configure base directory
BASE_DIR = "/home/locotoki/projects/alfred-agent-platform-v2/docs"
LOG_FILE = "/home/locotoki/projects/alfred-agent-platform-v2/doc-reference-update-log.txt"

# Dictionary to store old_name -> new_name mappings
file_mappings = {}

def kebab_case(filename):
    """Convert a filename to kebab-case format."""
    # Strip Zone.Identifier suffixes
    if ":Zone.Identifier" in filename:
        filename = filename.replace(":Zone.Identifier", "")
    
    # Replace spaces with hyphens
    filename = filename.replace(" ", "-")
    
    # Replace multiple hyphens with a single hyphen
    while "--" in filename:
        filename = filename.replace("--", "-")
    
    # Replace various Unicode dash characters
    filename = filename.replace("—", "-")  # em dash
    filename = filename.replace("–", "-")  # en dash
    filename = filename.replace("‑", "-")  # non-breaking hyphen
    
    # Replace other special characters
    filename = filename.replace("&", "and")
    filename = filename.replace(":", "")
    filename = filename.replace("?", "")
    filename = filename.replace("!", "")
    filename = filename.replace("#", "")
    filename = filename.replace("*", "")
    
    # Remove any numeric ID suffixes like "1eab4fd21ff08080a6ebccdf693562f3"
    filename = re.sub(r'-[0-9a-f]{32}', '', filename)
    
    # Trim hyphens from beginning and end
    filename = filename.strip("-")
    
    # Convert to lowercase
    return filename.lower()

def build_file_mapping():
    """Build a mapping of original filenames to their kebab-case versions."""
    for root, _, files in os.walk(BASE_DIR):
        for file in files:
            if file.endswith(".md"):
                kebab_file = kebab_case(file)
                if file != kebab_file:
                    file_mappings[file] = kebab_file
                    file_mappings[os.path.splitext(file)[0]] = os.path.splitext(kebab_file)[0]

def update_references():
    """Update file references in all markdown files."""
    with open(LOG_FILE, "w") as log:
        log.write(f"Document Reference Update Log - {os.popen('date').read().strip()}\n")
        log.write("====================================\n")
        
        # Process all markdown files
        for root, _, files in os.walk(BASE_DIR):
            for file in files:
                if file.endswith(".md"):
                    file_path = os.path.join(root, file)
                    try:
                        with open(file_path, "r", encoding="utf-8") as f:
                            content = f.read()
                        
                        # Track if we've made changes to this file
                        changes_made = False
                        
                        # Look for markdown links with problematic filenames
                        link_pattern = re.compile(r'\[(.*?)\]\((.*?)\)')
                        
                        def replace_link(match):
                            nonlocal changes_made
                            link_text = match.group(1)
                            link_target = match.group(2)
                            
                            # Check if the link points to a file we've renamed
                            link_parts = link_target.split("/")
                            if len(link_parts) > 0:
                                filename = link_parts[-1]
                                filename_no_ext = os.path.splitext(filename)[0]
                                
                                if filename in file_mappings:
                                    link_parts[-1] = file_mappings[filename]
                                    changes_made = True
                                    log.write(f"In {file_path}: Updated link to {filename} → {file_mappings[filename]}\n")
                                    return f"[{link_text}]({'/'.join(link_parts)})"
                                elif filename_no_ext in file_mappings:
                                    # Handle case where link doesn't include extension
                                    link_parts[-1] = file_mappings[filename_no_ext] + os.path.splitext(filename)[1]
                                    changes_made = True
                                    log.write(f"In {file_path}: Updated link to {filename} → {file_mappings[filename_no_ext]}{os.path.splitext(filename)[1]}\n")
                                    return f"[{link_text}]({'/'.join(link_parts)})"
                            
                            # No change needed
                            return match.group(0)
                        
                        # Replace all links
                        updated_content = re.sub(link_pattern, replace_link, content)
                        
                        # If we made changes, write the file back
                        if changes_made:
                            with open(file_path, "w", encoding="utf-8") as f:
                                f.write(updated_content)
                            log.write(f"Updated references in: {file_path}\n")
                    
                    except Exception as e:
                        log.write(f"ERROR processing {file_path}: {str(e)}\n")
        
        log.write("====================================\n")
        log.write(f"Reference update completed - {os.popen('date').read().strip()}\n")

if __name__ == "__main__":
    print("Building file mapping...")
    build_file_mapping()
    print(f"Found {len(file_mappings)} files that need reference updates")
    
    print("Updating references in markdown files...")
    update_references()
    
    print(f"Reference update complete. Check {LOG_FILE} for details.")