# TLS & pgAudit Hardening Plan

## Overview
Post-baseline security hardening for the Alfred Agent Platform v2.

## Scope

### TLS Implementation
- [ ] Generate self-signed certs for development
- [ ] Mount cert volumes in all services
- [ ] Enable TLS for:
  - [ ] PostgreSQL (port 5432)
  - [ ] Redis (port 6379)
  - [ ] Prometheus (port 9090)
  - [ ] Grafana (port 3005)
  - [ ] Agent Core API (port 8011)
  
### pgAudit Configuration
- [ ] Add pgAudit to shared_preload_libraries
- [ ] Configure audit logging levels
- [ ] Set up log rotation
- [ ] Create audit dashboard in Grafana

### Secret Rotation
- [ ] Rotate all default passwords
- [ ] Update .env.example with secure defaults
- [ ] Add secret validation to bootstrap script
- [ ] Document secret management process

## Implementation Steps

1. **Create cert generation script**
   ```bash
   scripts/generate-certs.sh
   ```

2. **Update docker-compose.yml**
   - Add cert volume mounts
   - Update connection strings
   
3. **Update PostgreSQL configuration**
   ```
   ssl = on
   ssl_cert_file = '/certs/server.crt'
   ssl_key_file = '/certs/server.key'
   shared_preload_libraries = 'pg_stat_statements,pgaudit'
   ```

4. **Test with baseline**
   - Run `./scripts/check-core-health.sh`
   - Verify all services remain healthy
   - Update baseline hash if needed

## Success Criteria
- [ ] All services use TLS connections
- [ ] pgAudit logs all DDL and DML operations
- [ ] No hardcoded secrets in codebase
- [ ] Health checks still pass with hardening enabled

## Notes
- Maintain backward compatibility with development setup
- Document all breaking changes
- Create migration guide for existing deployments