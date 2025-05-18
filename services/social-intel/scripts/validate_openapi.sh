#!/bin/bash
# Validate the OpenAPI specification using redocly

echo "Validating OpenAPI schema..."
npx @redocly/cli lint api/openapi.yaml

if [ $? -eq 0 ]; then
  echo "✅ OpenAPI specification is valid!"
  exit 0
else
  echo "❌ OpenAPI specification has errors."
  exit 1
fi
