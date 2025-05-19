# Filename Normalization Tool

This tool normalizes filenames in the staging area to make them compatible with the document consolidation process.

## Background

The staging area contains many files with problematic filenames that include:
- Spaces and special characters
- Non-standard Unicode characters
- Long hexadecimal suffixes (e.g., `1eeb4fd21ff0817ab0e3cd8fdebde8f4`)
- Windows-specific `.Zone.Identifier` files

These files need to be normalized before they can be properly migrated to the main documentation structure.

## Features

- Removes spaces and special characters from filenames
- Converts filenames to lowercase with hyphens as separators
- Removes hexadecimal suffixes
- Optionally removes `.Zone.Identifier` files
- Creates a mapping file to track original and new filenames
- Supports dry run mode to preview changes without modifying files

## Usage

### Quick Start

To run the tool with default settings (dry run mode first):

```bash
./normalize_staging_files.sh --dry-run
```

This will show what changes would be made without actually modifying any files.

To actually rename the files:

```bash
./normalize_staging_files.sh
```

### Options

- `--dry-run`: Show what would be done without actually renaming files
- `--directory=DIR`: Specify a different staging directory
- `--mapping=FILE`: Specify a different mapping file location
- `--keep-zone-files`: Don't remove `.Zone.Identifier` files
- `--help`: Show help message

### Examples

```bash
# Run in dry mode to preview changes
./normalize_staging_files.sh --dry-run

# Normalize files in a specific directory
./normalize_staging_files.sh --directory=/path/to/different/staging-area

# Specify a custom mapping file location
./normalize_staging_files.sh --mapping=/path/to/custom/mapping.csv

# Keep .Zone.Identifier files
./normalize_staging_files.sh --keep-zone-files
```

## Output

The tool produces:

1. A CSV file mapping original filenames to new filenames
2. Logs showing which files were renamed, removed, or skipped
3. A summary of operations performed

The mapping file has the following format:

```
directory,original_filename,new_filename
RAG_service,RAG Service – Add‑On Artifacts 1eeb4fd21ff080ae948be7dc9e5cf411.md,rag-service-add-on-artifacts.md
RAG_service,RAG Service – Architectural RFC 1eeb4fd21ff080b6a44ced387219a795.md,rag-service-architectural-rfc.md
...
```

## Implementation Details

The normalization process follows these steps:

1. Walk through all files in the staging directory recursively
2. For each file:
   - Remove hexadecimal suffixes using regex pattern matching
   - Normalize Unicode characters to ASCII equivalents where possible
   - Replace special characters and spaces with hyphens
   - Convert to lowercase
   - Handle filename collisions by appending numbers if necessary
3. Create a mapping file for reference

## Integration with Document Migration

After normalizing filenames, the regular document migration process can proceed. The document migration tool (`doc_migration_inventory.py`) will work more effectively with normalized filenames.

## Troubleshooting

If you encounter issues:

1. Check the log output for error messages
2. Try running with `--dry-run` to diagnose potential problems
3. Ensure you have write permissions for the staging directory
4. If specific files are causing problems, you may need to handle them manually

## Notes

- The tool creates timestamped mapping files in the `outputs` directory
- The most recent mapping is also saved as `latest_filename_mapping.csv`
- Original filenames are preserved in the mapping for reference
