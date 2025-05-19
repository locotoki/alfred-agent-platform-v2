# Alfred‑Home : Architectural Synthesis

### Architectural Synthesis

1. **Layered shape emerging**

```
css
CopyEdit
[Channel adapters] → Pub/Sub bus → [Logic/LLM Orchestrator] → [Domain tools] → Postgres + Redis

```

- The *WhatsApp adapter* from the Integration guide fits the “channel adapter” role.
- The *Logic-Orchestrator* and *Domain tools* appear in both the Family MVP and the Multi-Tenant draft; they just need to agree on tenancy boundaries.
- Postgres **schema-per-tenant** plus RLS keeps queries simple and lets you share one HA cluster without cross-leak risk.
1. **Data-isolation strategy is coherent**

    RLS + `SET app.tenant` + pgvector indexes per schema is the right call for GDPR and for cheap multi-tenant hosting. It avoids the OR-mismatch you’d hit with a single shared table + `tenant_id` predicate. (Decision #1 in the draft) Alfred WhatsApp Family …Alfred Multi‑Tenant Age…

2. **Coordination Broker is the only new service**

    Everything else (adapters, orchestrator, policy engine) already exists in some form. A thin gRPC Broker—fronted by a Pub/Sub fallback for long-running ops—keeps cross-tenant calls explicit, audited, and rate-limited.

3. **Single message-envelope schema**

    Standardise on a small protobuf/JSON envelope: `{tenant_id, user_id, channel, kind, payload}`. All adapters publish to «alfred-ingest»; workers respond via «alfred-outbox». This removes ad-hoc POSTs in the minimum sample and lines up with the Integration guide’s outbound worker.

4. **Ops footprint**

    *Channel adapters* & *Broker* live on Cloud Run (burst to zero). *LLM orchestrator* on GKE (GPU pool). Shared Postgres, Redis, Pub/Sub already listed in both docs—simply tag resources with `tenant` for show-back billing.


---

### Gaps / open questions worth discussing

| Topic | Why it matters |
| --- | --- |
| **Template-management API** | Business & Family tenants both need WhatsApp template CRUD; centralise rather than per-adapter hacks. |
| **Per-tenant observability dashboards** | Family users want uptime SMS; business wants Slack alerts. Decide on Grafana folder & label strategy. |
| **Cross-tenant writes** | Draft says “likely no”, but status-setting in Slack could be a safe exception—need policy clause. |
| **Shared embeddings** | De-dup across tenants saves RAM but risks leakage—decide before building vector cache. |

---

### Recommended next decisions (in order)

1. **Confirm “schema-per-tenant + RLS”** as the canonical datastore pattern.
2. **Green-light gRPC Coordination Broker** with a Pub/Sub fallback queue for > 2 s ops.
3. **Ratify the minimal protobuf envelope** so adapters can ship ASAP.
4. **Spin up a spike**: run the Family MVP code path under `tenant_id=personal`, then issue a mocked gRPC call to a stub `B-Alfred` to verify the Broker & RLS interplay.
5. **Lock a performance SLO** for cross-tenant calls (e.g., p95 < 400 ms end-to-end) so the Broker team has a target.
