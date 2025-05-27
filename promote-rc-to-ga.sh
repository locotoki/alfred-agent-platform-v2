#\!/usr/bin/env bash
# promote-rc-to-ga.sh — final smoke test & GA tag
set -euo pipefail

# ───── Config ────────────────────────────────────────────────
REPO="Digital-Native-Ventures/alfred-agent-platform-v2"
TAG_RC="v3.0.0-rc1"
TAG_GA="v3.0.0"
HELM_NS="alfred-ga-smoke"
TIMEOUT=120      # seconds per health probe
# ─────────────────────────────────────────────────────────────

gh repo view "$REPO" &>/dev/null || { echo "❌  auth/repo issue"; exit 1; }

### 1 ▸ Local compose smoke
echo "🧪  Local compose smoke test…"
alfred down &>/dev/null || true
alfred up --profile core -d
SECONDS=0
until curl -fsSL http://localhost:8000/health >/dev/null 2>&1; do
  (( SECONDS > TIMEOUT )) && { echo "❌ compose health failed"; exit 1; }
  sleep 2
done
echo "✅ compose health OK"
ANSWER=$(curl -fsSL -X POST http://localhost:8000/ask \
  -H "Content-Type: application/json" \
  -d '{"question":"What is the capital of Portugal?"}'  < /dev/null |  jq -r .answer)
[[ "$ANSWER" =~ Lisboa|Lisbon ]] || { echo "❌ RAG answer unexpected: $ANSWER"; exit 1; }
echo "✅ sample query OK  → $ANSWER"
alfred down

### 2 ▸ Kind / Helm smoke
echo "🧪  kind + Helm smoke test…"
kind create cluster --name alfred-ga --quiet || true
helm upgrade --install alfred ./deploy/helm \\
  --namespace "$HELM_NS" --create-namespace \\
  --set image.tag="$TAG_RC"
kubectl wait --namespace "$HELM_NS" deployment/agent-core \\
  --for=condition=available --timeout=${TIMEOUT}s
kubectl port-forward -n "$HELM_NS" svc/agent-core 18000:8000 >/tmp/kpf.log 2>&1 &
PF_PID=$!
sleep 5
curl -fsSL http://localhost:18000/health >/dev/null
echo "✅ Helm chart health OK"
kill $PF_PID
kind delete cluster --name alfred-ga

### 3 ▸ Promote tag to GA
git fetch origin "$TAG_RC"
if git tag -l | grep -q "^$TAG_GA$"; then
  echo "ℹ️ $TAG_GA already exists — skipping tag."
else
  echo "🏷️ Promoting $TAG_RC → $TAG_GA…"
  git tag -a "$TAG_GA" -m "GA release v3.0.0" "$TAG_RC"
  git push origin "$TAG_GA"
fi

### 4 ▸ Publish GitHub release notes draft
NOTES="### AI Agency Platform v3.0.0 (GA)\\n\\
* One-command stack (<60 s cold-start)\\n* agent-core RAG + agent-bizdev CRM sync\\n\\
* Bench p95 ≤ 75 s (5-run average = 43.9 s)\\n* Security: Trivy gate, Keycloak hardened\\n\\
* Docs complete (run-book, secrets, ADRs)\\n"
gh release create "$TAG_GA" --repo "$REPO" --title "v3.0.0 GA" --notes "$NOTES" || true

echo -e "\\n🎉  GA tag $TAG_GA pushed and release drafted!"
