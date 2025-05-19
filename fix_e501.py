#!/usr/bin/env python3
"""
Script to help fix E501 (line too long) violations.
"""
import os
import re


def fix_e501_violations(violations_file="flake8_violations.txt"):
    """Fix E501 violations."""
    if not os.path.exists(violations_file):
        os.system(f"flake8 . > {violations_file} 2>/dev/null || true")

    violations = []

    with open(violations_file, "r") as f:
        for line in f:
            if "E501" not in line:
                continue

            # Parse the violation line
            match = re.match(
                r"(.+):(\d+):(\d+): E501 line too long \((\d+) > \d+ characters\)", line
            )
            if match:
                filepath, line_num, col_num, length = match.groups()
                violations.append(
                    {
                        "filepath": filepath,
                        "line_num": int(line_num),
                        "col_num": int(col_num),
                        "length": int(length),
                    }
                )

    # Group by file
    files = {}
    for v in violations:
        filepath = v["filepath"]
        if filepath not in files:
            files[filepath] = []
        files[filepath].append(v)

    print(f"Found {len(violations)} E501 violations in {len(files)} files\n")

    # Report violations by file
    for filepath, file_violations in sorted(files.items()):
        print(f"\n{filepath}: {len(file_violations)} violations")
        for v in sorted(file_violations, key=lambda x: x["line_num"]):
            print(f"  Line {v['line_num']}: {v['length']} chars (column {v['col_num']})")

    print("\nFix suggestions:")
    print("1. Break long lines at logical points (commas, operators)")
    print("2. Use parentheses for implicit line continuation")
    print("3. Extract long strings into variables")
    print("4. Consider using black formatter: black <file>")


if __name__ == "__main__":
    fix_e501_violations()
