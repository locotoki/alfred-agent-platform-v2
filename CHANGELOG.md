# Changelog

All notable changes to the Alfred Agent Platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Implemented MSSQL health check probe for SQL Server databases
- Created comprehensive documentation for all database probes in docs/PROBES.md
- Added alerts for MSSQL database health monitoring
- Extended smoke test compose file with MSSQL support

## [0.5.0] - 2025-05-15

### Added
- Fixed Grafana probe to add environment variable fallback with default to `http://localhost:3005`
- Standardized health checks for all priority services (model-registry, model-router, redis, alfred-core, social-intel)
- Added proper entrypoint.sh scripts with secure defaults (set -euo pipefail)
- Created skeletal alert rules for each standardized service
- Added lightweight health check smoke test to CI pipeline
- Implemented model-registry fixes for WSL compatibility

### Changed
- ❯ Python code is now auto-formatted with Black in CI and pre-commit. Run `make format` before pushing.
- Created new GitHub workflow for applying Black automatically (`apply-black.yml`)
- Added in-depth documentation for Black formatting standards (`docs/formatting/BLACK-FORMATTING-STANDARDS.md`)
- Created pre-commit hooks for consistent formatting in local development
- Applied Black 24.1.1 formatting across entire codebase
- Updated CI pipeline to enforce strict Black checks with fail-fast feedback
- Standardized code formatting for better maintainability
- Applied isort for consistent import ordering
- Updated Makefile with improved format and test commands
- Enhanced pre-commit configuration for better developer experience
- Updated dependabot to monitor Black versions
- Added mypy exclusions for duplicate modules
- Marked legacy health check scripts as deprecated
- Updated agent_core/health.py to comply with health check standard

### Fixed
- Resolved WSL mount issue in model-registry service
- Removed temporary CI workarounds used for PR #25 (Health Check Standardization)
- Restored proper CI checks after module reorganization
- Fixed inconsistent code style across Python files

## [0.3.0-healthcheck-full] - 2025-05-14

### Added
- Complete standardization of healthcheck binary v0.4.0 across all services
- Added metrics port exposure (9091) for all containers
- Created audit script to identify legacy healthcheck implementations
- Created bulk update script for standardizing healthcheck across services
- Added verification script to ensure metrics are properly exported
- Enhanced CI validation to detect services without proper health checks
- Updated Prometheus configuration to include all service metrics endpoints

### Changed
- Updated all remaining Dockerfiles to use healthcheck binary v0.4.0
- Standardized health check configuration across services
- Added consistent metrics port exposure for monitoring
- Enhanced documentation of health check implementation

### Removed
- Legacy health check scripts and configurations
- Deprecated service-specific health probe implementations

## [0.2.0-phase1] - 2025-05-13

### Added
- Upgraded healthcheck binary to v0.4.0 across all key services
- Added metrics port exposure (9091) to all services
- Configured healthcheck binary to export Prometheus metrics with `--export-prom` flag
- New job configuration in Prometheus for collecting service_health metrics
- Enhanced Grafana dashboard with service_health metrics visualization
- Implemented tightened health check timings for different service classes
- Added metrics linting script for validating Prometheus metrics format
- Created documentation for metrics exporter implementation in `docs/METRICS_EXPORTER_UPGRADE.md`

### Changed
- Updated Docker service configurations with separate health check timing profiles
- Enhanced health check command structure for improved monitoring

### Fixed
- Standardized metrics port configuration across all services
- Consistent metrics format for better Prometheus compatibility

## [0.1.0] - 2025-05-01

### Added
- Initial platform implementation
- Core agent services
- Basic monitoring with Prometheus and Grafana
- Docker compose configuration for local development
- CI/CD pipeline integration

### Changed
- Standardized health check endpoints
- Improved service discovery

### Fixed
- Multiple Docker networking issues
- Service dependencies and startup ordering