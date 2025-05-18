# CLAUDE.md – Development & CI Workflow
_Alfred Agent Platform v2_

## 0 • Scope
This document is the **single source of truth** for how Claude–based contributors work on the repository.
It covers local dev, required pre‑commit checks, the disposable **kind‑in‑CI** pipeline, and secrets policy.

---

## 1 • Branch Naming
| Work type | Pattern | Example |
|-----------|---------|---------|
| Feature  | `feature/phase-<N>.<M>-<topic>` | `feature/phase-8.2-alert-explain` |
| Chore    | `chore/<topic>`               | `chore/kind-ci-local-dev`        |
| Hot‑fix  | `fix/<short-desc>`            | `fix/alert-runbook-link`         |

---

## 2 • Local Development (Docker Desktop)

1. **Bootstrap**
   ```bash
   git clone git@github.com:alfred-agent-platform-v2/alfred.git
   pip install pre-commit && pre-commit install
   cp .env.sample .env.dev   # fill Slack tokens & webhook
   ```

2. **Start the diagnostics bot**
   ```bash
   docker compose -f deploy/docker-compose.diagnostics.yml up -d
   ```

3. **Smoke‑test in Slack**
   ```text
   /diag health
   /diag metrics alfred-core
   ```
   Expect ✔️/❌ table or Grafana link.

4. **Run checks before pushing**
   ```bash
   pre-commit run --all-files   # fmt, lint, mypy
   tox -e py                    # unit tests
   ```

5. **Tear down**
   ```bash
   docker compose -f deploy/docker-compose.diagnostics.yml down
   ```

---

## 3 • CI Pipeline – Kind‑in‑CI

The GitHub Action creates a throw‑away Kubernetes cluster, installs Alfred via Helm, and runs an integration smoke‑test.

```yaml
jobs:
  kind-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: helm/kind-action@v1          # spins up a kind cluster

      - name: Deploy Alfred
        run: |
          helm upgrade --install alfred ./charts/alfred             --set diagnostics.enabled=true             --set diagnostics.env.SLACK_ALERT_WEBHOOK=https://httpbin.org/post

      - name: Diag smoke‑test
        run: pytest tests/integration/test_diag_smoke.py
```

### Required status checks
Only the following must be green to merge:

* **pre‑commit / lint‑typing**
* **pytest**
* **kind‑test**
* **docker build‑and‑push** (if Dockerfile changed)

---

## 4 • Toolchain Rules

| Area | Rule |
|------|------|
| Formatting | Black & isort via **pre‑commit** – never push unformatted code. |
| Typing | `mypy --strict` enforced on `alfred.*` and `scripts.*`. |
| Poetry | Run `poetry lock --no-update` after editing `pyproject.toml`. Commit the lock file. |
| Docker | Images build from `docker/diagnostics-bot/Dockerfile`; tags pushed by workflow `docker-diagnostics-bot.yml`. |

---

## 5 • Secrets Policy

* **`.env.sample`** is version‑controlled; **`.env.dev`** (with real tokens) is **git‑ignored**.
* CI secrets live in _GitHub > Repository > Settings > Secrets and variables > Actions_.
* Helm never contains plain‑text secrets; kind‑in‑CI injects a dummy webhook (`https://httpbin.org/post`).

---

## 6 • Releasing

1. Bump version with `./scripts/bump_version.sh <new>`
2. `git tag v<new>` → push → CI publishes Docker images
3. Update `CHANGELOG.md`

---

---

## 7 • GitHub CLI Setup & Permissions

To execute Sprint workflows and automated tasks, ensure GitHub CLI has proper permissions:

### Required Token Scopes
- `repo` - Full repository access
- `workflow` - Update GitHub Actions
- `write:discussion` - Comment on issues
- `project` - Manage project boards

### Quick Setup Check
```bash
# Verify authentication
gh auth status

# Test permissions
gh pr list  # Should list PRs
gh issue list  # Should list issues

# If these fail, reconfigure:
gh auth login  # Use PAT with required scopes
```

### Handling Permission Failures

When GitHub operations fail with permission errors:

1. **Use manual fallbacks**
   ```bash
   # Generate web URLs for manual actions
   echo "https://github.com/locotoki/alfred-agent-platform-v2/pull/new/BRANCH"
   ```

2. **Create command scripts**
   ```bash
   # Save commands for later execution
   ./docs/sprint5/manual_pr_commands.sh
   ```

3. **Document manual steps**
   - See `docs/CLAUDE_GITHUB_SETUP.md` for detailed setup
   - Always provide web UI alternatives
   - Create detailed step-by-step guides

### Best Practice
Before starting Sprint work:
1. Run `gh auth status`
2. Test with `gh pr list`
3. If blocked, use manual procedures
4. Document any permission issues

For complete GitHub CLI setup guide, see `docs/CLAUDE_GITHUB_SETUP.md`.

---

_Updated: 2025‑05‑17_
