# Keycloak Helm Chart

This chart deploys a hardened Keycloak instance for the AI-Agency platform.

## Security Features

- TLS enabled by default
- Admin console disabled (`KC_SPI_CONSOLE_ENABLED=false`)
- Realm export job for backup/migration

## Prerequisites

Before deploying this chart, create the required Kubernetes secret:

```bash
kubectl create secret generic keycloak-admin \
  --from-literal=username=admin \
  --from-literal=password=<secure-password>
```

> **Note:** Admin credentials now injected via `keycloak-admin` secret.
