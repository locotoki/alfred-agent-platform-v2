# External‑Facing SaaS RAG Playbook

# External‑Facing SaaS RAG Playbook

*(For multi‑tenant products serving paying customers)*

---

## 1 Architecture & Scope – Multi‑tenant Cloud

| Aspect | Choice | Notes |
| --- | --- | --- |
| Collections | `tenant:<customer‑org>:business` (+ internal personal & biz) | RBAC enforced in Gateway. |
| Ingress | Customer uploads, public API, integrations | Per‑tenant queue & worker. |
| Embedding | Managed GPU pool (A100/H100) | Autoscale via KEDA. |
| Vector store | Qdrant cluster (3 × replicas) | Per‑tenant encryption keys. |
| Gateway | Public, WAF, mTLS mesh, multi‑region | Data‑residency US/EU. |
| LLM tiers | GPT‑4o (premium), Mixtral (free) | Prompt logs hashed. |
| Auth | Supabase multi‑tenant + RBAC + TOTP | OAuth apps per tenant. |
| Observability | Grafana Cloud + Loki | SLO per customer; alert hooks. |

---

## 2 Agents

| Agent | Purpose | SaaS‑specific Note |
| --- | --- | --- |
| **Support Bot** | Draft KB, ticket replies | Zendesk / Intercom integration |
| **Community‑Mod Bot** | Community moderation | Discord/Slack sentiment |
| **Pricing‑Experiment Bot** | Landing page A/B, churn analysis | Plausible + Stripe |
| **(Solo‑Biz agents)** | Product build & ops | Apply tenant filters |

---

## 3 Security & Compliance

| Control Area | Measure |
| --- | --- |
| Data isolation | Per‑tenant encryption keys; Gateway collection ACL |
| Secrets | Vault dynamic DB creds (15‑min), mTLS service mesh |
| Compliance | SOC‑2 Lite, EU DPA, ongoing bug bounty |
| Incident comms | Public status page, RCA ≤ 5 days |
| RTBF | Automated purge + audit log export ≤ 24 h |

Annual third‑party pentest; WAF bot‑fight mode.

---

## 4 Reliability & SLOs

| SLO | Target |
| --- | --- |
| Global p95 | ≤ 300 ms |
| Tenant‑specific error rate | < 0.1 % |
| Data‑ingest lag | < 60 s |

KEDA autoscale on Gateway RPS & queue depth; runbooks for GPU saturation.

---

## 5 Monetization & Growth

- **Tier matrix:** Free (Mixtral) → Pro (GPT‑4o, 10 k vectors) → Enterprise (dedicated GPU).
- **Experiment engine:** Pricing‑Bot creates landing page variants; Plausible chooses winner.
- **Community loop:** Mod‑Bot flags feature requests; auto‑files GitHub issues.

---

## 6 Support & Community

- Support‑Bot drafts replies; human reviews until confidence > 0.9.
- Community‑Mod Bot escalates TOS violations; posts daily sentiment report.

---

## 7 Scalability & Cost

| Resource | Trigger | Action |
| --- | --- | --- |
| 1 B vectors | Add Qdrant shard | Rebalance cluster |
| GPU util > 80 % 15 m | Add A100 node | Terraform scale set |
| Cloud spend > $5 k/mo | Optimize hotspot tenants | Tiered storage |

---

## 8 Next Steps

1. Stand up Qdrant cluster (3 nodes) + multi‑region Gateway.
2. Integrate Supabase RBAC & SSO.
3. Launch Support‑Bot + KB ingestion.
4. Configure Plausible + Pricing‑Experiment Bot.
5. Schedule annual external pentest & open bug‑bounty.

---

*Deliver enterprise‑grade retrieval‑augmented intelligence to every customer with auditable security and scale.*
