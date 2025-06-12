## [v1.0.7] – 2025-06-12
### Added
- Local-dev health fixes for Apple-silicon & WSL 2 (#707)

### Changed
- Disabled failing Qdrant health-check in dev
- Supabase Studio probe switched to TCP (port 3001)

### Fixed
- db-auth (GoTrue) schema & migration errors
## [v0.9.14-beta2] - 2025-06-04
* Infra E2E harness merged
* Stub agents moved to **extras** profile

## v0.9.12-beta2 · Baseline hash stabilised (`03b31b03`) — deterministic audit script

### Changed
* Stubbed model-registry (FastAPI) until schema ADR lands- Infra E2E harness added; stub services moved to extras.
- ADR-001 Auth & Tenancy (JWT, SOPS, JWKS rotation)
- ADR-002 Event Contract Catalog (CloudEvents + Protobuf)
- Supply-chain security scaffold: cosign signatures, SLSA 2 provenance, Trivy gate, SBOM

## [v0.9.20-beta2] – 2025-06-05
* Auth hardening: JWKS endpoint implemented and deployed
* Pending: JWT contract test & secret-rotation docs (auto-merge in progress)
* Security: Supply-chain workflows active and monitored
