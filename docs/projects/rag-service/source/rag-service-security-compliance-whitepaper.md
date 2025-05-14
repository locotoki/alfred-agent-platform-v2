# RAG Service – security_compliance_whitepaper

# Security & Compliance White‑Paper

## Data Classification

| Tier | Example | Storage | Retention |
| --- | --- | --- | --- |
| Personal | PII, personal notes | Namespace `tenant:<uid>:personal` | 90 days hot + cold archive |
| Business | Policies, runbooks | Namespace `tenant:<org>:business` | 3 y |

## Controls

- **Encryption at rest**: AES‑256 for Qdrant & MinIO.
- **TLS in flight**: mTLS Gateway↔︎Qdrant, TLS 1.3 external.
- **Auth**: Supabase JWT, RBAC claims → namespace ACL.
- **Audit**: Conductor trace includes `persona`, `tenant_id`.
- **GDPR Delete**: `DELETE /v1/personal/{{uid}}` purges vectors + S3 objects.

## Threat Model

| Threat | Mitigation |
| --- | --- |
| Lateral movement between personas | Namespace isolation, row‑level ACL |
| Vector poisoning | Signed ingestion events, checksum at ingest |
| GPU DoS via huge embeds | Max token check (8 k), 429 throttle |