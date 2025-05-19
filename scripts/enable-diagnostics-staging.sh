#!/bin/bash
# Enable diagnostics in staging

echo "Enabling diagnostics in staging..."
helm upgrade alfred ./charts/alfred -n staging \
  --set slack.diagnostics.enabled=true \
  --reuse-values

echo "Diagnostics enabled. Test with:"
echo "  /diag health"
echo "  /diag metrics"
