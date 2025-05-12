#!/usr/bin/env python3
"""
Script to generate a summary of documentation fixes made to the Alfred Agent Platform v2.
"""

import os
import re
import glob
from datetime import datetime

# Configuration
RENAME_LOG = "/home/locotoki/projects/alfred-agent-platform-v2/doc-rename-log.txt"
REFERENCE_LOG = "/home/locotoki/projects/alfred-agent-platform-v2/doc-reference-update-log.txt"
GAPS_REPORT = "/home/locotoki/projects/alfred-agent-platform-v2/doc-gaps-report.md"
OUTPUT_FILE = "/home/locotoki/projects/alfred-agent-platform-v2/DOCUMENTATION_FIXES.md"
DOCS_DIR = "/home/locotoki/projects/alfred-agent-platform-v2/docs"

def count_files_by_extension(directory, extension):
    """Count the number of files with the given extension in a directory (recursive)."""
    return len(glob.glob(f"{directory}/**/*.{extension}", recursive=True))

def count_renamed_files():
    """Count the number of renamed files from the log."""
    if not os.path.exists(RENAME_LOG):
        return 0
    
    renamed_count = 0
    with open(RENAME_LOG, 'r') as f:
        for line in f:
            if line.startswith('Renamed:'):
                renamed_count += 1
    return renamed_count

def count_updated_references():
    """Count the number of updated references from the log."""
    if not os.path.exists(REFERENCE_LOG):
        return 0
    
    updated_count = 0
    with open(REFERENCE_LOG, 'r') as f:
        for line in f:
            if 'Updated link to' in line:
                updated_count += 1
    return updated_count

def extract_gaps_summary():
    """Extract the summary of documentation gaps from the gaps report."""
    if not os.path.exists(GAPS_REPORT):
        return "No gaps report found."
    
    with open(GAPS_REPORT, 'r') as f:
        content = f.read()
    
    # Extract the summary section
    summary_match = re.search(r'## Summary\s+(.+?)(?=##|$)', content, re.DOTALL)
    if summary_match:
        return summary_match.group(1).strip()
    return "Summary section not found in gaps report."

def get_new_docs():
    """Get a list of newly created documentation files."""
    # For this example, we'll just detect the financial-tax agent architecture file
    new_docs = []
    
    if os.path.exists('/home/locotoki/projects/alfred-agent-platform-v2/docs/agents/financial_tax/financial-tax-agent-architecture.md'):
        new_docs.append('docs/agents/financial_tax/financial-tax-agent-architecture.md')
    
    return new_docs

def generate_summary():
    """Generate a summary of all documentation fixes."""
    renamed_count = count_renamed_files()
    updated_refs = count_updated_references()
    total_md_files = count_files_by_extension(DOCS_DIR, "md")
    new_docs = get_new_docs()
    gaps_summary = extract_gaps_summary()
    
    with open(OUTPUT_FILE, 'w') as f:
        f.write("# Documentation Fixes Summary\n\n")
        f.write(f"*Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*\n\n")
        
        f.write("## Overview\n\n")
        f.write(f"- **Total Documentation Files**: {total_md_files}\n")
        f.write(f"- **Files Renamed**: {renamed_count}\n")
        f.write(f"- **References Updated**: {updated_refs}\n")
        f.write(f"- **New Files Created**: {len(new_docs)}\n\n")
        
        f.write("## Filename Normalization\n\n")
        f.write("The following changes were made to normalize filenames:\n\n")
        f.write("- Converted spaces to hyphens in filenames\n")
        f.write("- Standardized Unicode special characters\n")
        f.write("- Removed numeric ID suffixes from imported files\n")
        f.write("- Applied consistent kebab-case naming convention\n")
        f.write("- Removed Windows metadata files (.Zone.Identifier)\n\n")
        
        f.write("## Reference Updates\n\n")
        f.write("References in Markdown files were updated to reflect the new filenames:\n\n")
        f.write("- Updated Markdown links to use the new kebab-case filenames\n")
        f.write("- Fixed broken links caused by filename inconsistencies\n")
        f.write("- Ensured cross-references remain functional\n\n")
        
        if new_docs:
            f.write("## New Documentation\n\n")
            f.write("The following new documentation files were created to address gaps:\n\n")
            for doc in new_docs:
                f.write(f"- {doc}\n")
            f.write("\n")
        
        f.write("## Documentation Gaps\n\n")
        f.write("Documentation gaps analysis for the Financial-Tax Agent (Phase 6):\n\n")
        f.write(gaps_summary)
        f.write("\n\n")
        
        f.write("## Next Steps\n\n")
        f.write("1. **Complete Critical Gaps**: Create the remaining required documentation for the Financial-Tax Agent\n")
        f.write("2. **Git Management**: Add all renamed files to git and commit the changes\n")
        f.write("3. **Template Refinement**: Use the created Financial-Tax Agent architecture document as a template for other missing documents\n")
        f.write("4. **Regular Maintenance**: Regularly run the documentation tools to maintain consistency\n")
        f.write("5. **Documentation Workflow**: Integrate these scripts into the documentation workflow to ensure ongoing compliance\n\n")
        
        f.write("## Tools Used\n\n")
        f.write("The following scripts were created for documentation maintenance:\n\n")
        f.write("- `scripts/fix-doc-filenames.sh`: Renames files according to convention\n")
        f.write("- `scripts/update-doc-references.py`: Updates references to renamed files\n")
        f.write("- `scripts/identify-doc-gaps.py`: Identifies missing documentation\n")
        f.write("- `scripts/generate-doc-fix-summary.py`: Generates this summary report\n")

if __name__ == "__main__":
    generate_summary()
    print(f"Documentation fixes summary generated: {OUTPUT_FILE}")