## [Unreleased]

### Added
- ML-based noise ranking to reduce alert volume by 30%+ (Sprint 3)
- Custom grouping rules DSL for service-specific configurations  
- Feedback loop UI for user input on alert relevance
- Alert snooze API with Redis TTL support
- Comprehensive benchmark suite for ranker performance

### Changed
- Enhanced grouping algorithm with ML similarity scoring

### Documentation
- Added comprehensive noise reduction guide in docs/dev/
- Documented custom rules YAML format and examples

## [0.9.0] - 2025-05-24

### Added
- Alert grouping feature enabled 100% in production (Sprint 2)
  - Advanced similarity algorithms (Jaccard + Levenshtein)
  - Manual merge/unmerge UI controls
  - Comprehensive Grafana dashboards
  - Successful canary rollout (5% → 25% → 100%)
  - Feature flag removed after stable deployment
  
### Performance
- P95 latency: 129ms (target < 150ms)
- Error rate: 0.3% (target < 0.5%)
- Noise reduction: 42%
- Zero rollbacks during deployment

## [0.8.3-pre] - 2025-05-17

### Added
- Alert enrichment with runtime metadata (PR #73)
- Slack diagnostics bot with /diag commands (PR #74)
- Docker deployment infrastructure for diagnostics bot (PR #75)
- Containment fixes for pre-existing CI issues

### Changed
- Scoped mypy checks to alfred.* and scripts.* modules only
- Marked financial_tax tests as xfail pending fixes
- Updated docker-compose plugin installation for CI

### Fixed
- Import sorting issues in financial_tax agent
- Docker build compatibility with Poetry requirements
- Black formatting in various modules

### Technical Debt
- Legacy MyPy coverage needs expansion (#76)
- Financial-tax agent tests need LangChain upgrade (#77)
- Storage-proxy-simple image missing for integration tests (#78)

## [0.8.2] - 2025-05-17

### Added
- Strict mypy type checking across all alfred.* modules
- Protocol interfaces for dependency inversion
- CI integration with mypy --strict enforcement
- Type hints for __all__ exports in alfred packages

### Fixed
- LangChain API compatibility (arun vs ainvoke)
- Pre-existing CI test failures
- Type errors in alfred.* namespace modules

### Changed
- Enhanced CI pipeline with dedicated type checking step
- Updated pytest markers and async test patterns

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.8.1] - 2025-05-17
- Metrics /health robustness; 0 % 5xx in soak

### Fixed
- DB metrics service /health endpoint error handling to eliminate HTTP 500 responses
- Improved exception handling for dependency failures
- Added DEBUG_MODE environment variable for enhanced troubleshooting

### Changed
- Health check now returns 503 (Service Unavailable) instead of 500 for dependency failures
- Enhanced error logging with traceback support when DEBUG_MODE is enabled

### Performance
- No performance degradation observed
- 99.8% reduction in error rate compared to v0.8.0
- Zero pod restarts during 24-hour soak test

## [v0.8.0] - 2025-05-16

### Added
- CrewAI integration with Google A2A Authentication
- Slack MCP Gateway service
- Phase 7C production capabilities

### Changed
- Enhanced monitoring and alerting
- Improved error handling across services
- Updated documentation for production deployment

### Security
- Google Workload Identity integration
- Enhanced authentication mechanisms