#!/usr/bin/env python3
"""Script to fix class method decorators in test files."""

import re

# Fix the HF embedder file
with open("tests/alfred/ml/test_hf_embedder.py", "r") as f:
    content = f.read()

# Find each test method and fix its decorator
test_pattern = r"(@pytest\.mark\.xfail.*?)\n(\s*)def (test_\w+\(self(?:,\s*[^)]+)?\))"
class_methods = re.findall(test_pattern, content)

# Replace each match
for decorator, indent, method_def in class_methods:
    old = f"{decorator}\n{indent}def {method_def}"
    new = f"{indent}def {method_def}:\n{indent}    {decorator}"
    content = content.replace(old, new)

with open("tests/alfred/ml/test_hf_embedder.py", "w") as f:
    f.write(content)

print("Fixed test_hf_embedder.py")

# Fix the FAISS index file
with open("tests/backend/ml/test_faiss_index.py", "r") as f:
    content = f.read()

# Find each test method and fix its decorator
test_pattern = r"(@pytest\.mark\.xfail.*?)\n(\s*)def (test_\w+\(self(?:,\s*[^)]+)?\))"
class_methods = re.findall(test_pattern, content)

# Replace each match
for decorator, indent, method_def in class_methods:
    old = f"{decorator}\n{indent}def {method_def}"
    new = f"{indent}def {method_def}:\n{indent}    {decorator}"
    content = content.replace(old, new)

with open("tests/backend/ml/test_faiss_index.py", "w") as f:
    f.write(content)

print("Fixed test_faiss_index.py")
