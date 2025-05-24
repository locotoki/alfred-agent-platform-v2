# Quick Start · v0.9.6 +

Get the whole stack running in **≤ 60 s cold** using pre-built images from GHCR.

```bash
# 1 ─ clone
git clone https://github.com/locotoki/alfred-agent-platform-v2.git
cd alfred-agent-platform-v2

# 2 ─ start
alfred up            # wrapper for: docker compose up -d

# 3 ─ open UI
open http://localhost:3000
```

The compose file now pulls

* `ghcr.io/locotoki/agent-core:v0.9.6`
* `ghcr.io/locotoki/agent-bizdev:edge`

so no local Docker builds are required.

**Stop the stack** — `alfred down`

For release notes and perf numbers see [v0.9.6](https://github.com/locotoki/alfred-agent-platform-v2/releases/tag/v0.9.6).
