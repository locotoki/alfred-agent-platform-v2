# Keycloak Hardening Guide 🔐 *(Draft)*

> **Scope:** GA v3.0.0 — baseline security posture.

## 1  Admin User
```bash
export KEYCLOAK_ADMIN=alfred-admin
export KEYCLOAK_ADMIN_PASSWORD="$(openssl rand -base64 24)"
```
Set via Docker/Helm secrets.

## 2  Themes & Login
- Disable user self-registration.
- Require email verification.

## 3  HTTPS
Use ingress terminating TLS (cert-manager cluster issuer).

## 4  Backup & Upgrade
Scheduled `kc.sh export` nightly to MinIO.

<\!-- TODO: add OPA policy link once integrated -->
