# Secret Management & Rotation

| Environment | Mechanism | Notes |
|-------------|-----------|-------|
| Local dev   | `.env` file (git-ignored) | Run `source bootstrap-dev.sh` |
| Docker-compose | `env_file` with `${VAR:?err}` | Secrets passed via `.env` |
| Kubernetes  | Sealed Secrets (SOPS) ➜ K8s Secret | Encrypted YAML committed; decrypted in CI |

## Rotation
Use `make rotate-secret NAME=API_KEY VALUE=$(gcloud secrets versions access ...)`.

## SOPS Key Rotation

### Prerequisites
- Install SOPS: `brew install sops` or `go install go.mozilla.org/sops/v3/cmd/sops@latest`
- Install age: `brew install age` or `go install filippo.io/age/cmd/...@latest`

### Key Rotation Process

1. **Generate new age key pair**
   ```bash
   age-keygen -o ~/.config/sops/age/new-key.txt
   export NEW_AGE_KEY=$(cat ~/.config/sops/age/new-key.txt | grep "# public key:" | cut -d: -f2 | tr -d ' ')
   ```

2. **Update .sops.yaml with new key**
   ```bash
   # Add new key to existing keys (don't remove old key yet)
   sops --add-age $NEW_AGE_KEY --in-place k8s/secrets/*.enc.yaml
   ```

3. **Re-encrypt all secrets with new key**
   ```bash
   for file in k8s/secrets/*.enc.yaml; do
     sops updatekeys "$file"
   done
   ```

4. **Test decryption with new key**
   ```bash
   export SOPS_AGE_KEY_FILE=~/.config/sops/age/new-key.txt
   sops -d k8s/secrets/db.enc.yaml
   ```

5. **Remove old key from .sops.yaml after verification**
   ```bash
   # Update .sops.yaml to only include new key
   sops --rm-age OLD_AGE_KEY --in-place k8s/secrets/*.enc.yaml
   ```

### Emergency Key Recovery

If the primary key is compromised:

1. **Immediate rotation (all secrets)**
   ```bash
   ./scripts/emergency-key-rotation.sh
   ```

2. **Generate new passwords**
   ```bash
   export NEW_DB_PASSWORD=$(pwgen 32 1)
   export NEW_REDIS_PASSWORD=$(pwgen 32 1)
   export NEW_JWT_SECRET=$(openssl rand -base64 64)
   ```

3. **Update and deploy**
   ```bash
   make rotate-all-secrets
   kubectl rollout restart deployment -n alfred
   ```

### Best Practices

- **Weekly rotation** for production secrets
- **Never commit** unencrypted secrets to git
- **Use different keys** for staging vs production
- **Backup age keys** securely (separate from code repo)
- **Monitor** secret access in audit logs