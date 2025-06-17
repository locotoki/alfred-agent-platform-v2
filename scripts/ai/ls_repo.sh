#\!/usr/bin/env bash
echo "Top-level tree:"
tree -L 2 -I '.git < /dev/null | node_modules|__pycache__'
echo "-------------------------"
echo ".github workflows:"
ls -1 .github/workflows 2>/dev/null || true
echo "-------------------------"
echo "Package managers present:"
ls -1 */requirements.txt */package.json 2>/dev/null || true
