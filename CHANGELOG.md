# Changelog

All notable changes to the Alfred Agent Platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Applied Black 24.1.1 formatting across entire codebase
- Updated CI pipeline to enforce strict Black checks
- Standardized code formatting for better maintainability

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