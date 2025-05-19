# Deployment Checklist

Use this checklist when deploying the refactored Docker Compose configuration to your main project.

## Pre-Deployment

- [ ] Backup your existing Docker Compose files
- [ ] Backup your existing .env file
- [ ] Make sure all running containers are properly documented (use `docker ps`)
- [ ] Document any custom modifications to your current setup

## File Transfer

- [ ] Copy all docker-compose*.yml files to your main project
- [ ] Copy alfred.sh to your main project
- [ ] Copy .env.example to your main project (if needed)
- [ ] Copy MIGRATION.md and README.md for reference

## Environment Configuration

- [ ] Update your .env file with all required variables
- [ ] Verify path references match your environment
- [ ] Check volume mount paths
- [ ] Verify build contexts if building images locally

## Initial Testing

- [ ] Run basic validation: `./tests/validate-compose.sh`
- [ ] Start only core services: `./alfred.sh start --components=core`
- [ ] Verify core services are running: `./alfred.sh status`
- [ ] Check logs for any errors: `./alfred.sh logs`

## Component Testing

For each component group:
- [ ] Start component: `./alfred.sh start --components=<component>`
- [ ] Verify services are running: `./alfred.sh status`
- [ ] Test basic functionality
- [ ] Check all health checks: `docker ps` (look for health status)

## Final Steps

- [ ] Stop all services: `./alfred.sh stop --force`
- [ ] Start with all required components: `./alfred.sh start --components=core,agents,ui`
- [ ] Run end-to-end tests on the platform
- [ ] Document any issues or adjustments made

## Production Deployment

- [ ] Ensure all secrets and credentials are secured
- [ ] Use production configuration: `./alfred.sh start --env=prod --components=core,agents,ui`
- [ ] Set up monitoring: `./alfred.sh start --components=monitoring`
- [ ] Verify all health checks are passing in production

## Rollback Plan

If issues arise:
- [ ] Stop all services: `./alfred.sh stop --force`
- [ ] Restore original Docker Compose files
- [ ] Restart using previous method
- [ ] Document issues for resolution
