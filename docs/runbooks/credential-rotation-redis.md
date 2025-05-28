# Credential Rotation (Redis)

> **Status:** Ready  
> **Linked issue:** #574  

## Purpose
Rotate the Redis AUTH password used by caching and queue workers with zero message loss.

## Prerequisites
- Cluster admin access to Redis instance  
- `redis-cli` available  
- Access to Kubernetes namespace `platform`  

## Procedure
1. **Generate new password**  
   ```bash
   openssl rand -base64 32
   ```

2. **Configure second password (dual-auth window)**  
   ```bash
   redis-cli ACL SETUSER default on >oldpass +@all
   redis-cli ACL SETUSER rotating on >NEWPASS +@all
   ```

3. **Update Kubernetes secret and restart consumers**  
   ```bash
   kubectl -n platform delete secret redis-auth
   kubectl -n platform create secret generic redis-auth --from-literal=password='<NEWPASS>'
   kubectl rollout restart deployment agent-core worker-bus
   ```

4. **Remove legacy password**  
   ```bash
   redis-cli ACL SETUSER default >NEWPASS
   redis-cli ACL DELUSER rotating
   ```

## Validation
- `redis-cli PING` returns `PONG` with new password; application logs show successful queue operations.

## Rollback
Re-enable previous password with `ACL SETUSER`.