# PostgreSQL Security Hardening Guide

## Incident Response Summary (2025-05-26)

### Attack Details
- **Type**: Kinsing cryptocurrency miner infection
- **Impact**: 752% CPU usage (8 cores), container compromise
- **Vector**: Likely brute-force or exposed Docker API
- **Status**: Contained and remediated

### Immediate Actions Taken
1. Container network isolated and CPU limited
2. Forensic snapshot created: `pg-compromised:kinsing-2025-05-26`
3. Evidence collected in `/var/tmp/incident-2025-05-26/`
4. Container stopped and renamed to `db-postgres-infected-2025-05-26`
5. No lateral movement detected to other containers

## Security Hardening Implemented

### 1. Network Security
```yaml
ports:
  # Only bind to localhost
  - "127.0.0.1:5432:5432"
```

### 2. Authentication Hardening
- Changed from `trust` to `scram-sha-256` authentication
- Strong password generation required
- Connection logging enabled

### 3. Resource Limits
```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
```

### 4. Container Security
- Read-only root filesystem (where possible)
- No new privileges
- tmpfs for /tmp to prevent persistent malware

### 5. Monitoring & Alerting
```sql
-- Enable connection logging
log_connections = on
log_disconnections = on
log_statement = ddl
shared_preload_libraries = pg_stat_statements
```

## Fail2Ban Configuration

Create `/etc/fail2ban/filter.d/postgresql.conf`:
```ini
[Definition]
failregex = ^.*FATAL:  password authentication failed for user ".*"$
            ^.*FATAL:  no pg_hba.conf entry for host .*, user .*, database .*$
ignoreregex =
```

Create `/etc/fail2ban/jail.d/postgresql.conf`:
```ini
[postgresql]
enabled = true
filter = postgresql
action = iptables-multiport[name=postgresql, port="5432", protocol=tcp]
logpath = /var/lib/docker/volumes/alfred-db-postgres-data/_data/pg_log/postgresql-*.log
maxretry = 5
findtime = 600
bantime = 3600
```

## pg_hba.conf Hardening

Add to PostgreSQL configuration:
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             all                                     scram-sha-256
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             172.18.0.0/16           scram-sha-256
# Reject all other connections
host    all             all             0.0.0.0/0               reject
```

## Monitoring Commands

### Check for suspicious activity
```bash
# Monitor CPU usage
docker stats db-postgres

# Check running processes
docker exec db-postgres ps aux | grep -v postgres

# Review recent connections
docker exec db-postgres psql -U postgres -c "
SELECT datname, usename, client_addr, state, query_start, state_change
FROM pg_stat_activity
WHERE client_addr IS NOT NULL
ORDER BY query_start DESC;"

# Check for large or suspicious queries
docker exec db-postgres psql -U postgres -c "
SELECT query, calls, mean_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;"
```

### Security Audit Queries
```sql
-- Check for superuser accounts
SELECT usename, usesuper FROM pg_user WHERE usesuper = true;

-- Review user permissions
SELECT grantee, table_schema, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee NOT IN ('postgres', 'PUBLIC');

-- Check for unusual extensions
SELECT * FROM pg_extension;
```

## Recovery Procedure

1. **Stop compromised container**
   ```bash
   docker stop db-postgres
   docker rename db-postgres db-postgres-compromised
   ```

2. **Run secure setup script**
   ```bash
   ./scripts/secure-postgres-setup.sh
   ```

3. **Update application passwords**
   - Update all `.env` files
   - Restart dependent services
   - Verify connectivity

4. **Monitor for 24 hours**
   - Check logs every hour
   - Monitor CPU/memory usage
   - Review connection attempts

## Prevention Checklist

- [ ] PostgreSQL bound only to internal network
- [ ] Strong passwords (32+ characters)
- [ ] scram-sha-256 authentication enabled
- [ ] Connection logging enabled
- [ ] Resource limits configured
- [ ] Fail2ban configured
- [ ] Regular security updates
- [ ] Backup strategy implemented
- [ ] Monitoring alerts configured
- [ ] Incident response plan documented

## References
- [Kinsing Malware Analysis](https://www.aquasec.com/blog/threat-alert-kinsing-malware-container/)
- [PostgreSQL Security Best Practices](https://www.postgresql.org/docs/current/auth-pg-hba-conf.html)
- [Docker Security Hardening](https://docs.docker.com/engine/security/)
