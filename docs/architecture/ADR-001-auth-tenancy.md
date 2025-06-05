# ADR-001: Authentication & Tenancy

| Status | Decided |
|--------|---------|
| Date   | 2025-06-05 |
| Decision | **JWT (RS256)** with `sub`, `tenant`, `scope` claims.<br>Row-level multi-tenant isolation.<br>Secrets encrypted via **SOPS**.<br>JWKS weekly rotation via GitHub Actions. |

## Context
* Multi-tenant SaaS + on-prem core slice.
* Agents must verify tokens offline (edge).
* Lightweight ops—avoid heavy Vault for GA.

## Decision
1. **Token**: RS256 JWT.  Header `kid`, payload:  
   ```json
   { "sub":"<uuid>", "tenant":"<uuid>", "scope":"rag.query" }
   ```
2. **Tenant isolation**: DB/Qdrant row filter `tenant_id = :tenant`.
3. **Secrets**: K8s Sealed-Secret (SOPS/age); `.sops.yaml` governs KMS keys.
4. **Key rotation**: JWKS endpoint exposed by Keycloak stub; rotated weekly via GH Action.

## Consequences
* All agents import `alfred_sdk.auth.verify_jwt()` (PyJWT).
* CI adds jwt-contract tests + sealed-secret lint.
* Deployment docs updated with `rotate-jwks` workflow.