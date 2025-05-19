#!/usr/bin/env python3
"""
Script to automatically remove unused imports based on flake8 F401 violations.
"""
import os
import re
import sys


def fix_f401_violations(violations_file):
    """Parse violations file and remove unused imports."""
    fixed_files = set()

    with open(violations_file, "r") as f:
        for line in f:
            if "F401" not in line:
                continue

            # Parse the violation line
            match = re.match(r"(.+):(\d+):(\d+): F401 \'(.+)\' imported but unused", line)
            if not match:
                continue

            filepath, line_num, col_num, import_name = match.groups()
            line_num = int(line_num) - 1  # Convert to 0-based index

            # Read the file
            with open(filepath, "r") as infile:
                lines = infile.readlines()

            # Check if the line contains the unused import
            if line_num < len(lines):
                import_line = lines[line_num]

                # Handle different import patterns
                if f"import {import_name}" in import_line:
                    # Direct import
                    if import_line.strip() == f"import {import_name}":
                        # Remove the entire line
                        lines[line_num] = ""
                    else:
                        # Multiple imports on one line, remove just this one
                        import_line = import_line.replace(f"import {import_name}", "")
                        import_line = import_line.replace(", ,", ",").replace(",,", ",")
                        import_line = import_line.replace("import ,", "import")
                        lines[line_num] = import_line

                elif f"from " in import_line and import_name in import_line:
                    # From import
                    module_part = import_name.rsplit(".", 1)[0] if "." in import_name else None
                    import_part = import_name.rsplit(".", 1)[-1]

                    if (
                        f" {import_part}" in import_line
                        or f"{import_part}," in import_line
                        or f"{import_part} " in import_line
                    ):
                        # Remove just this import
                        patterns = [
                            f", {import_part}",
                            f"{import_part}, ",
                            f"{import_part}",
                        ]

                        for pattern in patterns:
                            if pattern in import_line:
                                new_line = import_line.replace(pattern, "", 1)
                                # Clean up any resulting issues
                                new_line = new_line.replace("from  import", "from")
                                new_line = new_line.replace("import , ", "import ")
                                new_line = new_line.replace("import ,", "import")
                                new_line = new_line.replace(", , ", ", ")
                                new_line = new_line.replace("( )", "()")
                                new_line = new_line.replace("(, ", "(")
                                new_line = new_line.replace(", )", ")")
                                new_line = new_line.replace("import ()", "import")
                                new_line = new_line.strip()

                                # If the line is now effectively empty, remove it
                                if new_line in ["from", "import", "from import"]:
                                    lines[line_num] = ""
                                else:
                                    lines[line_num] = new_line + "\n"
                                break

                # Write back the file if we made changes
                if lines[line_num] != import_line:
                    with open(filepath, "w") as outfile:
                        outfile.writelines(lines)
                    fixed_files.add(filepath)
                    print(f"Fixed: {filepath}:{line_num+1} - Removed '{import_name}'")

    return fixed_files


if __name__ == "__main__":
    violations_file = sys.argv[1] if len(sys.argv) > 1 else "flake8_violations.txt"

    if not os.path.exists(violations_file):
        print(f"Violations file not found: {violations_file}")
        sys.exit(1)

    fixed_files = fix_f401_violations(violations_file)
    print(f"\nFixed {len(fixed_files)} files")
