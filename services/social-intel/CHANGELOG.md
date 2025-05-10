# Social-Intel Service Changelog

All notable changes to the Social-Intel service will be documented in this file.

## [1.0.1] - 2025-05-09

### Fixed
- Fixed 404 errors in API endpoints by adding JSON body parameter extraction to complement query parameter handling
- Fixed "minute must be in 0..59" error by ensuring timestamp format compatibility between JavaScript and Python services
- Added detailed logging for parameter extraction and processing
- Improved error handling for API requests
- Added support for A2A envelope format in all endpoints

### Technical Details
- Modified FastAPI endpoint handlers to accept both query parameters and JSON payloads
- Updated timestamp generation in ID fields to use milliseconds (matching JavaScript's Date.now())
- Added proper extraction of parameters from A2A envelope format
- Implemented graceful fallbacks when parameters are missing from either source
- See detailed documentation in `/docs/json-payload-fix.md` and `/docs/timestamp-fix.md`

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