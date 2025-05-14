# RAG Service – Future Roadmap

# RAG Service – Future Roadmap

> Status: Draft (rev 0.1 – 2025‑05‑09)
> 
> 
> This roadmap lists post‑MVP investments that harden, measure, and extend the shared RAG platform.
> 

| # | Epic | Why it matters | Deliverables | Target window |
| --- | --- | --- | --- | --- |
| **1** | **Quality Evaluation Harness** | Detect recall drift & regression before users complain. | • `eval/` golden set JSONL• `make test-rag` (Ragas)• Prometheus bridge `rag_eval_score` | Weeks 1‑2 post‑launch |
| **2** | **Load & Resiliency Testing** | Prevent outage when ingest spikes. | • k6 scripts (index & query)• CI perf gate (95‑latency < 300 ms)• Auto‑scale alert | Weeks 2‑3 |
| **3** | **SBOM & Vulnerability Scans** | Maintain supply‑chain security. | • Trivy scan in CI• `cyclonedx.json` artefact• Fail on HIGH CVEs | Week 3 |
| **4** | **Disaster Recovery & Backups** | Meet RPO=24 h, RTO=4 h for vectors. | • Runbook markdown• Snapshot ⇒ MinIO ⇒ rsync job• Restore drill script | Week 4 |
| **5** | **Schema Versioning & Deprecation Policy** | Keep agents stable as API evolves. | • `X-RAG-Schema` header• Version table in docs• Deprecation alert channel | Week 4 |
| **6** | **GDPR / Delete‑Me Support** | Users may request data erasure. | • `DELETE /v1/personal/{user}` endpoint• Qdrant payload purge job• Audit log entry | Weeks 5‑6 |
| **7** | **Agent Onboarding Guide** | Scale adoption without bespoke help. | • One‑pager in handbook• Code snippet per language• Workshop video | Week 5 |
| **8** | **Observability & SLO Dashboards** | Define “RAG is up & fast.” | • Grafana SLO panel• Alert rule: P95 < 250 ms, success ≥ 99 % | Week 6 |
| **9** | **Multi‑Modal Retrieval R&D** | Future text+image/code context. | • Vision encoder PoC• Code chunker PoC• Design note | Quarter +2 |
| **10** | **Multi‑Region / Geo‑Residency** | EU data‑sovereignty compliance. | • Region‑tagged collections• Gateway geo‑routing | Quarter +2 |

---

### Visual timeline (Gantt‑style)

```
W0  W1  W2  W3  W4  W5  W6  Q+2
|---MVP live----|
1: ███
2:     ███
3:        ██
4:            ██
5:            ██
6:                ███
7:                █
8:                █
9:                        ▂▂▂▂
10:                       ▂▂▂▂

```

### Ownership

- **Platform / RAG Guild** → Epics 1, 2, 4, 5, 8, 10
- **Security / Compliance Crew** → Epics 3, 6
- **DevRel & Enablement** → Epic 7
- **Research Group** → Epic 9

### Review cadence

Monthly roadmap review in **#rag-guild‑sync**; progress tracked in Linear board `RAG‑Platform`.

---

*Last edited: 2025‑05‑09*