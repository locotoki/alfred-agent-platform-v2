# Secret Management

| Environment | Mechanism | Notes |
|-------------|-----------|-------|
| Local dev   | `.env` file (git-ignored) | Run `source bootstrap-dev.sh` |
| Docker-compose | `env_file` with `${VAR:?err}` | Secrets passed via `.env` |
| Kubernetes  | Sealed Secrets (SOPS) ➜ K8s Secret | Encrypted YAML committed; decrypted in CI |

## Rotation
Use `make rotate-secret NAME=API_KEY VALUE=$(gcloud secrets versions access ...)`.