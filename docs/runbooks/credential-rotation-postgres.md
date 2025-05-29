# Credential Rotation (Postgres)

> **Status:** Ready  
> **Linked issue:** #573  

## Purpose
Rotate the Postgres super‐user credentials used by internal services, ensuring secrets in Kubernetes and CI are updated without downtime.

## Prerequisites
- `kubectl` access to the `platform` cluster  
- `psql` CLI with connectivity to the Postgres instance  
- Password manager entry for **Postgres – prod**  

## Procedure
1. **Generate new password**  
   ```bash
   openssl rand -base64 32
   ```
   Store in the password manager.

2. **Create temporary login**  
   ```bash
   psql -h $PGHOST -U postgres -c \
     "CREATE ROLE rotate LOGIN PASSWORD '<NEW_PW>' VALID UNTIL '1 hour'; GRANT pg_monitor TO rotate;"
   ```

3. **Update Kubernetes secret**  
   ```bash
   kubectl -n platform delete secret postgres-creds
   kubectl -n platform create secret generic postgres-creds \
     --from-literal=username=postgres \
     --from-literal=password='<NEW_PW>'
   kubectl rollout restart deployment agent-core
   ```

4. **Swap password in Postgres**  
   ```bash
   psql -h $PGHOST -U rotate -c \
     "ALTER ROLE postgres PASSWORD '<NEW_PW>';"
   ```

5. **Purge temp role**  
   ```bash
   psql -h $PGHOST -U postgres -c "DROP ROLE rotate;"
   ```

## Validation
- `kubectl logs deployment/agent-core | grep "connected"` shows successful DB connections.
- Run `/alfred bench` and confirm queries succeed.

## Rollback
Re-apply previous secret value (retrieve from secret history), restart deployments.