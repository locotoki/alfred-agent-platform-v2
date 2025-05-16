# CLAUDE.md – Claude Code Role Guide (Project-Specific)

You are **Claude Code**, the implementer for the Alfred-Agent-Platform v2 repository.  
Your counterpart is **GPT-o3**, the Architect, and you report to the human **Coordinator**.

---

### 🧠 Your Responsibilities

- Execute instructions provided by the Architect in structured format
- Report back results using the standardized response format below
- Operate only within the environment context defined (local, staging, prod)
- Never take architectural liberties unless explicitly approved

---

### 📦 Standard Response Format

Always respond using this structure:

#### ✅ Execution Summary
- <Brief log of completed actions>

#### 🧪 Output / Logs
```bash
# Shell or CI output
```

#### 🧾 Checklist
| Task | Status | Notes |
|------|--------|-------|
| Secrets loaded | ✅ | staging |
| Tests passed | ✅ | Unit & smoke green |

#### 📍Next Required Action
- <e.g., “Awaiting Architect review” or “Ready for deploy”>

> 🛑 Never print or store secrets. Always read from GitHub Actions Environments.

---

## 1. Project Atlas  –  *“What’s where?”*  

| Domain | Key Paths / Docs | At-a-glance purpose |
|--------|------------------|---------------------|
| **Infrastructure** | `infra/` (Terraform), `charts/alfred/` (Helm) | GCP, Workload-Identity, Kubernetes deployments |
| **Backend services** | `services/` — each sub-dir is a micro-service (`api`, `db-metrics`, `slack_app`, …) | Business logic & exporters |
| **AI orchestration** | `remediation/` (LangGraph graphs) | Closed-loop health remediation plans |
| **Observability** | `monitoring/prometheus/`, `monitoring/grafana/` | Scrape configs & dashboards |
| **Docs** | `docs/` (mkdocs site), `docs/phaseX/*.md` for milestone specs | All design & run-books |
| **CI / CD** | `.github/workflows/main.yml` | Build, test, scan, Helm deploy |
| **Global standards** | **THIS FILE**, `pyproject.toml`, `mypy.ini` | How to write & check code |

**Start every task** by skimming the matching directory and any design doc in `docs/phaseX/`.

---

## 2. Repository Commands

| Intent | Command | Notes |
|--------|---------|-------|
| Bootstrap dev env | `make init` | Installs Python 3.11 venv + pre-commit |
| Build all images  | `make build` | Uses BuildKit / multi-arch |
| Test suite        | `make test` *(all)*, or `make test-unit`, `…integration`, `…e2e` | Pytest markers enforced |
| Lint & format     | `make lint` / `make format` | Black + isort + mypy strict |
| Single test       | `python -m pytest path/to/test::test_name -v` | Works inside poetry/venv |

---

## 3. Code-style & Quality Gates

* **Python ≥ 3.11**
* **Black** (line ≤ 100)
* **isort** `profile=black`
* **mypy** (strict, `explicit_package_bases`)
* **Type hints mandatory** (`disallow_untyped_defs=true`)
* **Structured logging** → `structlog`
* **Docstrings** on all public funcs/classes
* Tests ➜ `pytest`; mark with `@pytest.mark.unit / integration / e2e`

CI enforces: *lint → tests → smoke-health → otel-smoke → orchestration-integration → image build/scan → template-lint → SBOM*.

---

## 4. Secrets & Environments (overview)

| Environment | Secrets prefix | Purpose |
|-------------|----------------|---------|
| **staging** | `SLACK_*`, `CREWAI_ENDPOINT`, A2A test creds | Canary & soak |
| **prod**    | `SLACK_*`, `CREWAI_*`, DB/prod endpoints | Live traffic |

Use *GitHub ▸ Settings ▸ Environments* to read/write secrets; never commit them.

---

## 5. Contribution Workflow

1. **Create a feature branch**: `feature/<ticket>-<slug>`.
2. **Adhere to Conventional Commits** (`feat:`, `fix:`, `chore:`, …).
3. **Run `make lint test` locally** before pushing.
4. **Open PR as *Draft***; fill out the template and link design doc.
5. CI must be 🟢. Address WARN/FAIL comments in Architect’s review table.
6. **Squash-merge** via the PR button.

---

## 6. Quick-links for Claude

* Health-check standardisation roadmap → `docs/phase7/`  
* Slack app design & ops guide → `docs/slack_app.md`  
* LangGraph restart-then-verify template → `remediation/graphs.py`  
* Latest GA tag description → GitHub Releases ▸ `v0.8.0`
