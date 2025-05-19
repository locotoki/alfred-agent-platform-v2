# Remaining Health Check Updates

## Current Status

The main `docker-compose.yml` file has been successfully updated to use proper health check commands with `curl` instead of the non-existent `healthcheck` binary. However, there are several other Docker Compose files in the repository that still reference the `healthcheck` binary.

## Files Needing Updates

The following files still need to be updated:

1. `/home/locotoki/projects/alfred-agent-platform-v2/docker-compose-clean.yml`
2. `/home/locotoki/projects/alfred-agent-platform-v2/docker-compose.override.mission-control.yml`
3. `/home/locotoki/projects/alfred-agent-platform-v2/docker-compose.override.ui-chat.yml`

Additionally, various backup and archive files contain outdated health check commands, but since these are backup files, they don't need to be updated as they are not actively used.

## Update Process

To update the remaining files, follow the same pattern used for the main `docker-compose.yml` file:

1. For HTTP endpoints:
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:<PORT>/health"]
     <<: *basic-health-check
   ```

2. For TCP endpoints:
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "telnet://localhost:<PORT>" || "nc", "-z", "localhost", "<PORT>"]
     <<: *basic-health-check
   ```

3. For Redis:
   ```yaml
   healthcheck:
     test: ["CMD", "curl", "-f", "http://localhost:9091/health"]
     <<: *basic-health-check
   ```

4. For PostgreSQL:
   ```yaml
   healthcheck:
     test: ["CMD", "pg_isready", "-U", "postgres"]
     interval: 5s
     timeout: 5s
     retries: 10
   ```

## Verification

After updating the remaining files, use the `scripts/healthcheck/verify-health-commands.sh` script to verify that all health check commands are properly formatted:

```bash
./scripts/healthcheck/verify-health-commands.sh
```

## Notes

- The secondary Docker Compose files are not used in the standard deployment, so they are lower priority
- Consider adding a pre-commit hook to check for "healthcheck" binary references
- Add documentation to warn against using the non-existent "healthcheck" binary

## Next Steps

1. Update `docker-compose-clean.yml`
2. Update override files
3. Update documentation to reflect the proper health check pattern
4. Communicate the changes to the team
