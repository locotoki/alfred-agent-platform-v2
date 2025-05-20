#!/bin/bash
set -e

echo "Running black with line-length=100..."
black --line-length=100 .

echo "Running isort with black profile..."
isort --profile black .

echo "Checking results..."
black --check .
isort --check .
