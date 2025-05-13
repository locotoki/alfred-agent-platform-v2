#!/usr/bin/env python3

import subprocess
import sys
import os


def main():
    print("Running pip to install and run Black formatter...")
    # Create the command as a string directly
    cmd_str = (
        f"{sys.executable} -m pip install --quiet --user black==24.1.1 && "
        f"{sys.executable} -m black "
        f'--exclude "(youtube-test-env/|migrations/|node_modules/|\\.git/|\\.mypy_cache/|\\.env/|\\.venv/|env/|venv/|\\.ipynb/)" '
        f"."
    )
    print(f"Running command: {cmd_str}")

    try:
        # Run the command in the shell
        result = subprocess.run(cmd_str, shell=True, check=True, text=True)
        print("Black formatting successful!")
        return 0
    except subprocess.CalledProcessError as e:
        print(f"Error running Black formatter: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
