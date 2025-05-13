#!/usr/bin/env bash
#
# Validate that Prometheus and Grafana are up and healthy.
# Exits non-zero if *any* check fails so CI can catch regressions.
#
# Requires: curl, jq (jq optional—pretty-prints JSON if present)
# Env var:  GF_SECURITY_ADMIN_PASSWORD  (defaults to 'admin')

set -euo pipefail

PROM_BASE="http://localhost:9090"
GRAF_BASE="http://localhost:3005"
GRAF_USER="admin"
GRAF_PASS="${GF_SECURITY_ADMIN_PASSWORD:-admin}"

# --- helper ---------------------------------------------------------------
status() { printf "%s … " "$1"; }
ok()     { echo "✅ ok"; }
fail()   { echo "❌ FAIL"; exit 1; }

json_pretty() {
  command -v jq >/dev/null 2>&1 && jq . || cat
}

# --- Prometheus -----------------------------------------------------------
status "Prometheus /-/healthy"
curl -fsSL "${PROM_BASE}/-/healthy" | grep -q "Healthy" && ok || fail

status "Prometheus /-/ready"
curl -fsSL "${PROM_BASE}/-/ready" | grep -q "Ready" && ok || fail

status "Prometheus /api/v1/query?query=up"
PROM_METRIC=$(curl -fsSL "${PROM_BASE}/api/v1/query?query=up")
echo "$PROM_METRIC" | grep -q '"status":"success"' && ok || fail

# --- Grafana --------------------------------------------------------------
status "Grafana /api/health"
GRAF_RES=$(curl -fsSL "${GRAF_BASE}/api/health" | json_pretty)
# Just check if there is a valid JSON response as we may not need auth
if echo "$GRAF_RES" | grep -q '"database"'; then
  ok
else
  # Try with auth as fallback
  GRAF_RES=$(curl -fsSL -u "${GRAF_USER}:${GRAF_PASS}" "${GRAF_BASE}/api/health" | json_pretty)
  echo "$GRAF_RES" | grep -q '"database"' && ok || fail
fi

status "Grafana Platform Health Dashboard"
GRAF_DASH=$(curl -fsSL "${GRAF_BASE}/api/search?query=Platform%20Health%20Dashboard" | json_pretty)
if echo "$GRAF_DASH" | grep -q "platform-health"; then
  ok
else
  echo "Platform Health Dashboard not found"
  fail
fi

# --- summary --------------------------------------------------------------
echo
echo "Monitoring validation complete – all green 🎉"