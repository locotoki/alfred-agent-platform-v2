# COORDINATOR.md — Copy‑Paste Operator Guide

*alfred-agent-platform-v2*
*Created: 26 May 2025 · Europe/Lisbon*

---

## 1. Role

You bridge the gap between **Architect (o3)** and **Claude Code CLI**: copy and paste architect‑provided task blocks, run them, capture the output, and report back.

```
Architect (o3)  →  Coordinator  →  Claude Code CLI
```

## 2. Daily Playbook

| Step                          | Command / Action                                                                       |
| ----------------------------- | -------------------------------------------------------------------------------------- |
| 1. Receive architect message  | Look for fenced block between `# ⇩⇩ CLAUDE CLI START ⇩⇩` and `# ⇧⇧ CLAUDE CLI END ⇧⇧`. |
| 2. Copy‑paste into terminal   | Use a bash shell at repo root.                                                         |
| 3. Watch for `DONE` in output | Indicates success.                                                                     |
| 4. Capture logs               | Copy last 30 lines or redirect to `logs/<task>.txt`.                                   |
| 5. Reply in chat              | Use template below.                                                                    |

## 3. Reply Template

````md
✅ Execution Summary
- Task ID / branch / PR link

🧪 Output / Logs
```console
# [paste key lines]
````

📍 Next Required Action

* Await review / fix failures / escalate blockers

```

## 4. Escalation SLA
| Situation | Action | Time |
|-----------|--------|------|
| Blocker (CI infra down, permission denied) | Tag **@alfred-architect-o3** in `#maintainers` | ≤ 30 min |
| Unclear or missing CLI block | Ask architect for clarification | Immediately |

## 5. Tips
- Use `set -euo pipefail` to stop on first error.
- Always paste block **as‑is**. Resist editing unless architect confirms.
- If script is long‑running, tee output: `… |& tee logs/task‑$(date +%s).log`.

---

**Remember:** You never author code—just execute and report. If it’s not in a block, it’s not for you to run.

```
