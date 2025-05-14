# Personal / Family RAG Playbook

# Personal / Family RAG Playbook

---

## 1 Architecture & Scope (Local‑Only)

| Aspect | Choice | Notes |
| --- | --- | --- |
| Collection | `tenant:<user‑id>:personal` | One per family member (or shared). |
| Ingress | Drag‑&‑drop, e‑mail forwarder, mobile scan | No 3rd‑party webhooks. |
| Embedding | `e5‑large‑v2` – CPU/GPU | Batch nightly on local GPU. |
| Vector store | Local Qdrant (Docker) | Encrypted NVMe partition. |
| Gateway | LAN‑only (`http://raspberrypi:8080`) | Tailscale optional. |
| LLM surface | Local Llama‑3‑8B via Ollama | Offline mode by default. |
| Auth | Device‑bound JWT | Family passcode. |

*Latency target < 150 ms; storage < 50 GB.*

### Shared Core

Hybrid search 5 %/95 %, `bge‑reranker‑large`, simple prompt scaffold.

---

## 2 Agents

| Agent | Purpose |
| --- | --- |
| **Alfred‑bot** | General household Q&A |
| **Budget‑Buddy** | Spend summaries & renewal nudges |
| **Legal‑Reminder** | Contract‑expiry alerts |
| **Memory‑Finder** | Photo & note retrieval |
| **Health‑Prompt** (opt) | Med reminders & vitals pings |

---

## 3 Typical Workflows

1. **Subscription reminder** – Budget‑Buddy queries RAG weekly → push notification.
2. **Find document** – Alfred‑bot `/v1/query` → answer with citation.
3. **Photo memory** – Memory‑Finder CLIP search → image carousel.

---

## 4 Automation Tiers (Home)

| Tier | Outcome | Add‑on |
| --- | --- | --- |
| Reactive Q&A | “Where is HVAC warranty?” | Base stack |
| Proactive nudges | Subscription & passport expiry | cron job |
| Dashboards | Budget heat‑map | Grafana on Pi |
| Home‑IoT | Pre‑heat tank on solar forecast | Home Assistant webhook |

---

## 5 Security & Privacy

- Full‑disk encryption; `gpg`‑encrypted backups nightly.
- LAN‑only Gateway; firewall blocks WAN in.
- Manual key rotation quarterly (Bitwarden).
- Purge docs > 5 yrs by cron.

---

## 6 Reliability Basics

- Local UPS; watchdog restarts Docker if crash.
- Daily backup verify; restore drill quarterly.

---

## 7 Next Steps

1. Install Docker + Qdrant + Ollama on home server.
2. Set up ingestion folder & e‑mail forwarder.
3. Create Budget‑Buddy cron (`subscriptions_next30d`).
4. Schedule weekly backup to external drive.

---

*Enjoy a searchable, private household knowledge base!*