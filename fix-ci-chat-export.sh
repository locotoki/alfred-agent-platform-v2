###############################################################################
# fix-ci-chat-export.sh  –  auto-format, test, and push fixes for #853 & #854
###############################################################################
set -euo pipefail

# ----------------- Backend (PR #853) ----------------------------------------
echo "🔧  Formatting backend (architect-api)…"
(
  cd services/architect-api
  black . --line-length 100
  isort . --profile black
  echo "🧪  Running backend tests…"
  python -m pytest -q
  echo "✅  Backend clean."
)

# ----------------- Frontend (PR #854) ---------------------------------------
echo "🔧  Formatting frontend (agent-orchestrator)…"
(
  cd services/agent-orchestrator
  pnpm install --frozen-lockfile
  pnpm exec prettier . --write
  pnpm exec eslint . --fix
  echo "🧪  Running React unit tests…"
  pnpm test -r
  echo "🧪  Running Cypress e2e…"
  pnpm exec cypress install
  pnpm exec cypress run --e2e
  echo "✅  Frontend clean."
)

# ----------------- Commit & push fixes --------------------------------------
git add services/architect-api services/agent-orchestrator
git commit -m "chore: CI fix – apply black/isort + prettier/eslint & green tests"
git push

echo "🚀  Pushed formatting & test fixes. Re-run CI checks on GitHub."