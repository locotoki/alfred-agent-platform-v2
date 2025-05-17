# Global Project Instructions – AI Agent Systems

These instructions apply to all infrastructure, LLM, and automation projects that follow the Alfred architecture pattern.

## 🧠 AI Project Roles

| Role | Description |
| --- | --- |
| Architect (`GPT-o3`) | Maintains system integrity, sequencing, and design cohesion |
| Claude Code | Implements shell/Git/infra steps from Architect |
| Coordinator | Reviews work, signs off, manages scope shifts |

## 🧱 Project Structure

All future projects should follow these layers:

1. **Namespace-Based Code Layout**
    
    All source code is placed under a root package (`project_name.*`) with a clear domain-specific folder hierarchy.
    
2. **Strict Typing from Day 1**
    
    Use `mypy --strict` and CI enforcement. Add `typing.Protocol` to formalize agent contracts.
    
3. **Single Responsibility Agents**
    
    Every agent (slackbot, remediator, planner, observer, graph-builder) should be a stand-alone process with a health endpoint, metrics, and lifecycle hooks.
    
4. **Phased Milestone Planning**
    
    Each milestone is tracked in `/docs/phaseX/` and scoped via `feature/phase-X-*` branches.
    
5. **Structured Prompting for LLM Coordination**
    
    Start all sessions with the Architect by restating milestone context and current checklist.
    

## 🛡️ CI/CD Guidelines

| Tooling | Requirement |
| --- | --- |
| GitHub Actions | Must lint, type-check, run unit tests |
| Helm | `helm template` must be clean for all charts |
| CI Logs | Must report all agent `/health` and errors |
| Version Tags | Semver (`vX.Y.Z`) with RC tags allowed |

## 📡 Observability Baseline

All agents must expose:

- `/health` (returns 200 or 503 only)
- `/metrics` (Prometheus, exported on `:8000` or `:9000`)
- Slack notification on error and startup (optional but preferred)

## 🔐 Secrets and Safety

- Use GitHub Environment secrets (`staging`, `prod`)
- No secrets in code or commits
- Support `DEBUG_MODE` or `LOG_LEVEL=debug` for troubleshooting

## 📘 Reference Project: `alfred-agent-platform-v2`

This platform serves as the canonical implementation for all principles outlined here.