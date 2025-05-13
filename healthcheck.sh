#!/bin/bash
# *********************************************************************
# DEPRECATED: This script is deprecated and will be removed in a future version.
# Please use the healthcheck binary v0.4.0 instead, which is now standardized
# across all services. See PR #22 for details.
# *********************************************************************

# Extract URL from args
URL=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --http)
      URL="$2"
      shift 2
      ;;
    *)
      URL="$1"
      shift
      ;;
  esac
done

if [ -z "$URL" ]; then
  echo "Error: No URL provided"
  exit 1
fi

curl -s "$URL"  < /dev/null |  grep -q "status" && exit 0 || exit 1