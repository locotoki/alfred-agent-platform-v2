# Secret Management Guide 🔐

> **Scope:** GA v3.0.0 core slice
> **Audience:** Devs, DevOps, Security

## 1  Storage & Encryption

| Environment | Storage Backend | Encryption-at-rest | Rotation |
| --- | --- | --- | --- |
| Local dev | .env + Doppler | AES-256 (Doppler) | Manual / on-demand |
| Staging | Doppler Secrets Manager | AES-256 | 90-day forced |

<\!-- TODO: add production Keycloak set-up once finalized -->

## 2  Rotation Workflow

```bash
# Example rotation helper
doppler secrets rotate --project alfred-platform --config prod
```

<\!-- TODO: include rollback strategy -->

## 3  Historical Secrets Cleanup

All historical secrets <2025-05-27 were flagged; BFG purge tracked in issues #532-#534.
