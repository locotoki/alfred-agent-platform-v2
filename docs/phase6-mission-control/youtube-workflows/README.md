# YouTube Workflows Integration

This directory contains documentation and implementation details for integrating YouTube workflows with the Alfred Agent Platform v2.

## Port Configuration (IMPORTANT)

- **Mission Control UI**: 3007
- **Social Intelligence Agent**: 9000 (DO NOT CHANGE)

See `PORT-STANDARD.md` in the project root for full port configuration details.

## Quick Start

1. **Run environment check script:**
   ```bash
   bash ./environment-check-script.sh
   ```

2. **Start the services:**
   ```bash
   # Start Social Intelligence Agent
   cd /home/locotoki/projects/alfred-agent-platform-v2
   docker-compose up -d social-intel
   
   # Start Mission Control UI
   cd /home/locotoki/projects/alfred-agent-platform-v2/services/mission-control
   npm run dev
   ```

3. **Access the workflows:**
   - Open http://localhost:3007/workflows
   - Select either Niche-Scout or Seed-to-Blueprint

## Directory Contents

- `environment-check-script.sh`: Validates environment setup and configuration
- `quick-start-guide.md`: Brief onboarding guide for new developers
- `implementation-plan.md`: Detailed implementation steps and technical details
- `implementation_status_final.md`: Current status of the implementation
- `troubleshooting-guide.md`: Solutions for common issues

## Key Features

1. **Niche-Scout**: Identifies trending YouTube niches with growth potential
2. **Seed-to-Blueprint**: Creates YouTube channel strategies from seed content
3. **Dynamic URL handling**: Adapts to different port configurations
4. **Robust fallbacks**: Mock data when Social Intelligence Agent is unavailable

## Development Notes

- All code uses dynamic URL detection to avoid hardcoded ports
- API proxies handle error states gracefully
- Mock data is provided for development and testing
- Environment check script validates configuration

For more details, see the implementation plan and status documents.