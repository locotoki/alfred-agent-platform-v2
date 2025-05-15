#!/bin/bash
# Temporary workaround for modernc.org/sqlite checksum verification issues
# 
# This script sets the GONOSUMDB environment variable to bypass checksum
# verification for the problematic modules in our database drivers.
#
# Usage:
#   source scripts/env/gonosumdb_sqlite.sh
#
# This will allow you to run `go test ./internal/db/...` without checksum failures.
# NOTE: This is a temporary workaround until issue #36 is resolved.

export GONOSUMDB="modernc.org/sqlite,modernc.org/libc"

echo "GONOSUMDB environment variable set to bypass checksum verification for:"
echo "- modernc.org/sqlite"
echo "- modernc.org/libc"
echo
echo "You can now run Go commands without checksum verification errors."
echo "This workaround will be active for the current shell session only."