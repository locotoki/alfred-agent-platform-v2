# Social-Intel Service Changelog

All notable changes to the Social-Intel service will be documented in this file.

## [1.0.0] - 2025-05-09

### Added
- PostgreSQL database integration with `features` table and `hot_niches_today` materialized view
- Nightly scoring script (`score_features.ts`) for opportunity calculation
- Database seeding mechanism with sample CSV data
- Comprehensive OpenAPI documentation with Swagger UI
- Load testing with k6 and GitHub Actions workflow
- Prometheus metrics with optimized latency buckets (0.05, 0.1, 0.2, 0.4, 0.8, 2s)
- Alert rules for monitoring latency, error rates, and data quality
- Canary deployment capability via `FEATURE_PROXY_ENABLED` flag

### Changed
- Transformed in-memory simulated data to real database persistence
- Updated metrics histograms for better performance monitoring
- Fully implemented all workflow endpoints:
  - `/niche-scout`
  - `/seed-to-blueprint`
  - `/workflow-history`
  - `/workflow-result/{id}`
  - `/scheduled-workflows`
  - `/schedule-workflow`

### Fixed
- OpenAPI specification validation issues
- Missing dependency for `aiohttp` in Dockerfile

### Security
- Added process for quarterly API key rotation
- Added security scanning for git secrets