# Solo‑Biz Internal RAG Playbook

# Solo‑Biz Internal RAG Playbook

*(For freelancers / digital‑product creators who process only **their own** business data – no external customer log‑ins)*

---

## 1 Architecture & Scope – Single‑Tenant Cloud

| Aspect | Choice | Notes |
| --- | --- | --- |
| Collections | `tenant:<user‑id>:personal` + `tenant:biz:<solo‑id>:business` | Separate personal vs biz docs. |
| Ingress | Stripe & Plaid webhooks, GitHub Actions, Notion export | All data owned by you. |
| Embedding | `e5‑large‑v2` on spot A100 (RunPod) | Hourly batch; CPU fallback. |
| Vector store | Managed Qdrant (Hetzner) | Daily snapshot to Wasabi. |
| Gateway | Public behind Cloudflare Zero‑Trust | 50 RPM limit; IP allow‑list. |
| LLM stack | Local Llama‑3 for drafts, GPT‑4o for polish | Cost alert > $20/day. |
| Auth | Supabase Auth (Google SSO) | 24‑h JWT; Vault DB creds. |

Latency target < 250 ms global.

---

## 2 Agents

| Agent | Purpose | Key Tools |
| --- | --- | --- |
| **BizDev‑Bot** | Market/TAM research | GPT‑o3 + browser fetch |
| **Code‑Smith** | Repo scaffolding, tests | GPT‑01‑pro + Copilot |
| **Design‑Drafter** | Wireframes, images | GPT‑4o‑Vision + SDXL |
| **Growth Bot** | SEO, ad‑copy, social | GPT‑o3 + analytics RAG |
| **Financial‑Tax Agent** | Liability forecasts, bookkeeping | Pandas + GPT‑4o |
| **Legal‑Compliance** | Contract review | GPT‑4o + regex |
| **Ops‑Pilot** | Infra edits, backups | local Llama‑3 + CLI |
| **RAG Optimizer** | Eval harness & index tuning | LangSmith scripts |

---

## 3 Workflows

- **Content production pipeline** – See Section 8.
- **Tax forecast** – Fin‑Tax agent monthly → XLSX + summary.
- **Infra snapshot** – Ops‑Pilot cron → Wasabi backup + Slack DM.

---

## 4 Security

- Cloudflare WAF; WireGuard internal overlay.
- Vault for secrets; JWT 24 h; daily encrypted backups.
- Quarterly Nessus scan; self‑signed pentest.

---

## 5 Reliability & Incident Response

| SLO | Target |
| --- | --- |
| Gateway p95 | ≤ 250 ms |
| Uptime | 99.9 % |
| Backup integrity | Verified nightly |

Sev‑1 ⇒ fail over to local Llama‑only mode & post status page.

---

## 6 Content Ops (Digital Content Business)

Refer to **Content Types & Pipeline** table for blog, newsletter, video, etc. Agents advance Trello cards; human approves Publish.

---

## 7 Cost Model (Typical)

| Item | Monthly |
| --- | --- |
| OpenAI tokens | $65 |
| GPU elec | $26 |
| VPS | $35 |
| Storage | $10 |
| Email API | $10 |
| **Total** | **≈ $149** |

---

## 8 Next Steps

1. Spin managed Qdrant + Postgres in Hetzner.
2. Configure Cloudflare Zero‑Trust tunnel.
3. Deploy Gateway + Ollama container.
4. Wire Stripe & Plaid webhooks to ingestion.
5. Enable Growth Bot weekly SEO cron.

---

*Run your entire solo business with agent teammates—zero extra head‑count.*
