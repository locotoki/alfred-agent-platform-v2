# ADR-010 · Dev-container hardening

Date: 2025-05-26
Status: DRAFT
Authors: o3 Architect

## Context / Problem

Local development containers inherit the host Ubuntu `/usr/lib/python3/dist-packages`. Continuous‑integration (CI) images scrub these directories, so the PYTHONPATH seen during `pytest‑core` and Licence‑gate differs between CI and laptops. This causes:

* False‑positive imports on laptops.
* Licence‑gate mismatches (extra GPL packages locally).
* Non‑reproducible builds and flaky smoke tests.

## Decision

Adopt a **multi‑stage Dockerfile** that:

1. Installs system dependencies in a **builder** stage.
2. Copies only `/app` and the project virtual‑env into a minimal **runtime** stage.
3. Sets `ENV PYTHONPATH=/workspace/.venv/lib/python3.11/site-packages` explicitly.
4. Fails `docker build` if any file is present under `/usr/lib/python*/dist-packages` in the final image.

## Consequences

* CI and dev environments share an identical package set—Licence‑gate and tests are authoritative.
* Image size drops \~250 MB (site‑packages stripped).
* Slightly longer builds due to multi‑stage copy (\~12 s on laptop).
* Developers must rebuild containers after dependency bumps.
