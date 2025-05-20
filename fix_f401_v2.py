#!/usr/bin/env python3
"""Improved script to automatically remove unused imports based on flake8 F401
violations.
"""
import os
import re
import sys
from collections import defaultdict


def parse_violation(line):
    """Parse a flake8 F401 violation line."""
    match = re.match(r"(.+):(\d+):(\d+): F401 \'(.+)\' imported but unused", line)
    if match:
        filepath, line_num, col_num, import_name = match.groups()
        return filepath, int(line_num) - 1, import_name
    return None, None, None


def get_import_pattern(import_name):
    """Get the pattern to search for in the import line."""
    parts = import_name.split(".")

    # For module.attribute imports, we need to check the full path
    patterns = []

    # Handle different import styles
    if len(parts) == 1:
        # Simple import: import foo
        patterns.extend(
            [
                f"import {import_name}",
                f"{import_name}",
            ]
        )
    else:
        # Module import: from module import attr or import module.attr
        module_path = ".".join(parts[:-1])
        attr_name = parts[-1]

        patterns.extend(
            [
                f"from {module_path} import {attr_name}",
                f"from {module_path} import ({attr_name}",
                f"from {module_path} import {attr_name},",
                f"from {module_path} import {attr_name} as",
                f"import {import_name}",
                attr_name,  # Just the attribute name for grouped imports
            ]
        )

    return patterns


def remove_import_from_line(line, import_name):
    """Remove the import from the line."""
    # Special handling for different import patterns
    parts = import_name.split(".")

    if len(parts) == 1:
        # Simple import
        attr_name = parts[0]
    else:
        # Module.attribute
        attr_name = parts[-1]

    # Try different removal patterns
    removal_patterns = [
        f", {attr_name}",
        f"{attr_name}, ",
        f"{attr_name}",
    ]

    for pattern in removal_patterns:
        if pattern in line:
            line = line.replace(pattern, "", 1)
            break

    # Clean up the line
    line = re.sub(r",\s*,", ",", line)  # Remove double commas
    line = re.sub(r",\s*\)", ")", line)  # Remove trailing comma before )
    line = re.sub(r"\(\s*,", "(", line)  # Remove leading comma after (
    line = re.sub(r"import\s*\(\s*\)", "import", line)  # Remove empty parens
    line = re.sub(r"from\s+[\w.]+\s+import\s*$", "", line)  # Remove empty imports
    line = re.sub(r"import\s*$", "", line)  # Remove bare import
    line = re.sub(r"^\s*,\s*", "", line)  # Remove leading comma

    # If we've removed everything meaningful, return empty string
    if line.strip() in ["from", "import", "from import", "()"]:
        return ""

    return line


def fix_file_imports(filepath, violations):
    """Fix imports in a single file."""
    with open(filepath, "r") as f:
        lines = f.readlines()

    modified = False

    # Process violations in reverse order to avoid line number shifts
    for line_num, import_name in sorted(violations, reverse=True):
        if line_num >= len(lines):
            continue

        import_line = lines[line_num]
        original_line = import_line

        # Remove the import
        new_line = remove_import_from_line(import_line, import_name)

        if new_line != original_line:
            if new_line.strip():
                lines[line_num] = new_line
            else:
                # Remove empty line
                lines[line_num] = ""
            modified = True
            print(f"Fixed: {filepath}:{line_num+1} - Removed '{import_name}'")

    if modified:
        with open(filepath, "w") as f:
            f.writelines(lines)

    return modified


def main(violations_file="flake8_violations.txt"):
    """Main function to process all violations."""
    if not os.path.exists(violations_file):
        # Re-run flake8 to get current violations
        os.system(f"flake8 . > {violations_file} 2>/dev/null || true")

    # Group violations by file
    violations_by_file = defaultdict(list)

    with open(violations_file, "r") as f:
        for line in f:
            if "F401" not in line:
                continue

            filepath, line_num, import_name = parse_violation(line)
            if filepath:
                violations_by_file[filepath].append((line_num, import_name))

    # Fix each file
    fixed_files = 0
    for filepath, violations in violations_by_file.items():
        if fix_file_imports(filepath, violations):
            fixed_files += 1

    print(f"\nFixed {fixed_files} files")

    # Re-run flake8 to see remaining violations
    os.system("flake8 . | grep F401 | wc -l")


if __name__ == "__main__":
    violations_file = sys.argv[1] if len(sys.argv) > 1 else "flake8_violations.txt"
    main(violations_file)  # type: ignore # Script-level code
