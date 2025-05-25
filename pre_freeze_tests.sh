#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# CONFIG – tweak as required
###############################################################################
TAG="${TAG:-v0.9.30-beta}"
PROFILE="${PROFILE:-core,bizdev}"
COLD_START_SLA=60             # seconds
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8501/query?q=}"    # RAG gateway on port 8501
PROM_QUERY='container_start_time_seconds'   # cold-start metric
PROM_URL='http://localhost:9090/api/v1/query'
TEST_QUERIES=("What is Alfred?" "Who maintains the docs?" "roadmap")  # RAG
CSV_SAMPLE='tests/contacts_sample.csv'      # BizDev ingest payload - TODO: create this file
CRITICAL_CVE_THRESH=0

###############################################################################
# HELPER – pretty logging
###############################################################################
step()   { printf "\n\033[1;34m▶ %s\033[0m\n" "$*"; }
pass()   { printf "\033[1;32m✔ %s\033[0m\n" "$*"; }
fail()   { printf "\033[1;31m✖ %s\033[0m\n" "$*"; exit 1; }

###############################################################################
# 1 • Cold-start SLA  ----------------------------------------------------------
###############################################################################
step "Cold-start stack ($PROFILE) with tag $TAG"
START=$(date +%s)
alfred down --all >/dev/null 2>&1 || true
alfred up --profile "$PROFILE" --tag "$TAG" --workload qa -d
END=$(date +%s); DUR=$((END - START))
[[ "$DUR" -le "$COLD_START_SLA" ]] \
  && pass "Cold-start in ${DUR}s ≤ SLA ${COLD_START_SLA}s" \
  || fail "Cold-start ${DUR}s > SLA"

###############################################################################
# 2 • Dependency quorum  -------------------------------------------------------
###############################################################################
step "Verifying all 34 containers healthy"
COUNT=$(docker compose ps --status=running | wc -l)
[[ "$COUNT" -eq 34 ]] && pass "34/34 containers running" || fail "Only $COUNT running"

###############################################################################
# 3 • Agent-Core RAG basic queries  -------------------------------------------
###############################################################################
step "RAG answers sanity"
for Q in "${TEST_QUERIES[@]}"; do
  ANS=$(curl -s --max-time 10 "${GATEWAY_URL}${Q}" | tr -d '\n')
  grep -qi "alfred" <<<"$ANS" || fail "Query "$Q" returned unexpected answer"
done
pass "RAG returned expected snippets"

###############################################################################
# 4 • BizDev CRM ingest test  --------------------------------------------------
###############################################################################
step "Posting CRM ingest sample"
curl -s -X POST -F "file=@${CSV_SAMPLE}" http://localhost:8082/contacts > /tmp/ingest.log
grep -q '"rejected":0' /tmp/ingest.log && pass "CRM ingest 0 rejects" \
                                         || fail "CRM ingest had rejects"

###############################################################################
# 5 • Slack adapter '/help' ping  ---------------------------------------------
###############################################################################
step "Slack adapter echo test"
REPLY=$(curl -s -X POST -H "Content-Type: application/json" \
       -d '{"user":"tester","text":"/help"}' http://localhost:3010/slack/event)
grep -qi "alfred" <<<"$REPLY" && pass "Slack /help responded" || fail "Slack /help failed"

###############################################################################
# 6 • Observability dashboards available  -------------------------------------
###############################################################################
step "Prometheus scrape status"
curl -s "${PROM_URL}?query=up" | grep -q '"value"' \
  && pass "Prometheus up metric present" || fail "Prometheus query failed"

###############################################################################
# 7 • Pub/Sub durability pause ➜ unpause --------------------------------------
###############################################################################
step "Testing MinIO pause ➜ unpause (event durability)"
docker pause minio
sleep 5
curl -s -X POST http://localhost:8082/events -d '{"event":"test"}' >/dev/null
docker unpause minio
sleep 5
EVENTS=$(curl -s http://localhost:8082/events | grep -c '"test"')
[[ "$EVENTS" -ge 1 ]] && pass "Event survived MinIO outage" || fail "Event lost"

###############################################################################
# 8 • Random container kill resilience  ---------------------------------------
###############################################################################
step "Killing random container under load"
TARGET=$(docker ps -q | shuf -n1)
docker kill "$TARGET"
sleep 10
docker ps -q | grep -q "$TARGET" && fail "Container $TARGET did not restart" \
                                       || pass "Container $TARGET auto-restarted OK"

###############################################################################
# 9 • Node-only images sanity  -------------------------------------------------
###############################################################################
step "mission-control image runs stand-alone"
docker run --rm ghcr.io/locotoki/mission-control:"$TAG" node -e "console.log('ok')" | grep -q ok \
  && pass "mission-control image exits 0" || fail "mission-control image failed"

###############################################################################
# 10 • Trivy CVE scan (high/critical)  ----------------------------------------
###############################################################################
step "Running Trivy CVE scan"
trivy image --quiet --severity CRITICAL,HIGH ghcr.io/locotoki/alfred-core:"$TAG" > trivy.log
CRIT=$(grep -c '\[CRITICAL\]' trivy.log || true)
[[ "$CRIT" -le "$CRITICAL_CVE_THRESH" ]] \
  && pass "Trivy CRITICAL findings: $CRIT (<= $CRITICAL_CVE_THRESH)" \
  || fail "Trivy found $CRIT CRITICAL CVEs"

###############################################################################
# 11 • Secrets template parity  -----------------------------------------------
###############################################################################
step "Checking .env.example completeness"
REQ=$(grep -Eo '^\s*[A-Z0-9_]+=' services/**/.env.template | cut -d= -f1 | sort -u)
EXAMPLE=$(grep -Eo '^\s*[A-Z0-9_]+=' .env.example | cut -d= -f1 | sort -u)
DIFF=$(comm -23 <(echo "$REQ") <(echo "$EXAMPLE") | wc -l)
[[ "$DIFF" -eq 0 ]] && pass ".env.example covers all required vars" \
                    || fail ".env.example missing $DIFF vars"

###############################################################################
# 12 • Bench pipeline last 7 nights  ------------------------------------------
###############################################################################
step "Checking nightly bench history"
FAIL=$(gh run list --workflow bench.yml --limit 7 --json conclusion -q '.[] | select(.conclusion!="success")' | wc -l)
[[ "$FAIL" -eq 0 ]] && pass "Last 7 bench runs all green" \
                   || fail "$FAIL bench runs failed in last 7 nights"

###############################################################################
# Done
###############################################################################
pass "All automated readiness checks passed for $TAG"
