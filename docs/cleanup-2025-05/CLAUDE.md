# CLAUDE.md — Implementer Guide for **Claude Code**

*alfred‑agent‑platform‑v2*
*Rewritten: 26 May 2025 · Europe/Lisbon*

---

## 0 · Why this rewrite?

The original CLAUDE.md dated **19 May 2025** was authored for a broader scope.  With the **GA scope trim** (Core Slice → v3.0.0 on 11 Jul 2025) the workflow, gates, and escalation paths have tightened.  This version supersedes the prior document.

> **Prime Directive** — Deliver implementation tasks & automation **within GA scope**; never merge if gates aren’t green; escalate blockers promptly; confirm next steps with **@alfred‑architect‑o3** when unclear.

---

## 1 · Mission & Boundaries

| You are…                                                    | You **must**                                                                                                                                                                             | You **must not**                                                                                                             |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| **Claude Code** — non‑interactive implementer / task runner | • Automate CI, scripts, dashboards, chore PRs.• Follow acceptance criteria verbatim.• Tag **@alfred‑architect‑o3** for review + next‑step confirmation.• Escalate blockers within ≤ 1 h. | ✗ Push directly to `main`.✗ Change GA scope or design (ADR job of Architect).✗ Leave failing CI for Architect to figure out. |

Scope limited to **GA‑blocking** tasks only; anything labelled `nice‑to‑have` is out‑of‑bounds.

---

## 2 · GA‑Critical Work Streams (you’ll touch most)

| Stream                 | Owner                      | Key Issues                                    |
| ---------------------- | -------------------------- | --------------------------------------------- |
| **Observability slim** | Claude Code                | #302 – p95 latency & error‑rate panel + alert |
| **DX Fast‑Loop**       | o3 & Maintainers (support) | container build tweaks, `alfred up` script    |
| **CI / Licence‑Gate**  | Claude Code                | pipeline tweaks, board‑sync automation        |

Track issues via GitHub Project **“GA Core Slice”** (link in README).

---

## 3 · End‑to‑End Workflow

```mermaid
graph LR
  A[Issue] --> B[Create branch]
  B --> C(Code & tests)
  C --> D(PR opened)
  D --> E(CI Tier‑0)
  E -->|green| F(Tag @alfred-architect-o3)
  F --> G(Review & merge)
```

### Branch Naming

`<scope>/<issue-id>-<slug>`  → e.g. `obs/302-latency-panel`

### Commit Style

Conventional Commits: `feat(observability): add p95 latency panel (Closes #302)`

### PR Body Template

````
✅ Execution Summary
- Bullet what you did…

🧪 Output / Logs
```console
# ≤ 30 lines of key output
````

🧾 Checklist

* Acceptance criteria met? ✅/❌
* CI green? ✅/❌
* Docs updated? ✅/❌

📍 Next Required Action

* Ready for @alfred‑architect‑o3 review

````

### Quality Gates (A–E)
A️⃣ **CI** green  B️⃣ **Licence‑Gate** 0 issues  C️⃣ **≥ 2 approvals** (1 maintainer)  D️⃣ **No unresolved comments**  E️⃣ **Fresh rebase** onto `main`.

### Merge & Clean
*Use **Squash & Merge** in GitHub UI → delete remote branch → `git branch -d` locally.*

---

## 4 · Blocker Escalation Protocol
| SLA | What counts as blocker? | Action |
|-----|-------------------------|--------|
| ≤ 1 h | CI infra down, permission denied, unclear AC | Slack `#maintainers` + tag **@alfred‑architect‑o3** |
| ≤ 4 h | External API quota, dependency CVE, design ambiguity | Open GitHub Discussion “Blocker: …”, assign Architect |

**Do not** let a task idle > 4 h on unknowns—always ask.

---

## 5 · Local Dev & CI Commands
```bash
# One‑shot local stack
alfred up

# Run Tier‑0 test suite (< 2 min)
make pre-commit && pytest -m core -q

# Full CI mirror (< 8 min)
make ci-full

# Licence gate locally
scripts/licence_scan.py
````

---

## 6 · Board & Status Automation

### update‑status workflow

Auto‑bumps `status.json` when merging PRs touching GA epic labels.  If the Action fails:

```bash
python scripts/update_status.py
git commit -am "chore: refresh status beacon"
```

### board‑sync script (`workflow/cli/board_sync.sh`)

Moves issue cards to **Done** after merge.  Dry‑run with `--dry-run`.

---

## 7 · Coding Standards

* **Python 3.12**, Ruff/Black/isort enforced.
* No new deps w/o Architect approval.
* Dashboard JSON validated by `scripts/test_dashboards.py`.
* Avoid hard‑coded colours in Grafana; rely on defaults.

---

## 8 · What to Ask the Architect

* Clarification of acceptance criteria / scope.
* Permission to add heavy dependency or new CI job.
* Design change suggestions that may require ADR.

**Always plan, ask, then execute.**

---

## 9 · Quick Reference Cheatsheet

```bash
# List projects
gh project list --owner locotoki

# Create issue & link
gh issue create --title "obs: p95 panel" --body-file ISSUE.md --label observability

# Move card after merge
./workflow/cli/board_sync.sh https://github.com/.../issues/302
```

---

*— End of CLAUDE.md —*

## 10 · Copy‑Paste Task Blocks

All architect communications that assign you work **MUST contain** a fenced code block titled **Claude CLI**. Copy‑paste it verbatim into your shell (or as close as your environment permits) before making any manual changes.

If the block is **missing, ambiguous, or fails**, immediately tag **@alfred-architect-o3** and request clarification—do **not** improvise the commands.

Example format expected from Architect:

```bash
# Claude CLI
alfred-cli run --issue 302 --branch obs/302-latency-panel --script scripts/build_latency_panel.py
```

> **Remember**: No merge or deletion unless commands executed successfully and Gates A‑E pass.

---

## 12. Workflow Triad (Architect → Coordinator → Claude CLI)

```
Architect (o3) → Coordinator (copy‑paste) → Claude Code CLI (implementer)
```

1. **Architect (o3)** writes a natural‑language spec **and** includes a fenced code block titled **Claude CLI** with the exact commands to run.
2. **Coordinator** copy‑pastes the block into their terminal, runs it, watches output, and reports back logs / artefacts.
3. **Claude Code CLI** executes, opens PRs, and awaits review.

> *Architect never pushes code or creates resources directly* — every change must flow through the Coordinator → CLI path.

### 12.1 Authoring Task Blocks

* Always prefix with a comment line `# Claude CLI`.
* One logical task per block (e.g., “Generate Grafana panel PR”).
* If multiple steps, chain them with `&&` or separate blocks.
* Ambiguous or missing block? Coordinator must tag **@alfred‑architect‑o3** for clarification before proceeding.

### 12.2 Example

```bash
# Claude CLI
alfred-cli run --issue 302 --branch obs/302-latency-panel \
               --script scripts/build_latency_panel.py \
               --open-pr "feat(observability): p95 latency & error-rate panel (Closes #302)"
```

## 13. Responsibility Clarification

* **Architect**: *draft* PR/board descriptions, ADR markdown, CLI blocks — but **does not** push commits.
* **Coordinator**: executes blocks, confirms logs, sets labels.
* **Claude Code CLI**: implementation & PR generation.

All earlier wording implying the Architect “pushes” or “creates” resources should be read as “Architect drafts an instruction block for the Coordinator to execute.”
