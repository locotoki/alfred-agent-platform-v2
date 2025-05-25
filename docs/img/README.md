# Screenshot Placeholders

This directory contains placeholders for the run-book screenshots. In a production environment, these would be replaced with actual screenshots captured at 1920x1080 resolution.

## Required Screenshots

1. **platform-architecture.png**
   - High-level architecture diagram showing all services and their connections
   - Should include: Slack Bot, Alfred Core, Agents, RAG Service, Monitoring stack

2. **keycloak-tls-login.png**
   - Keycloak login page with HTTPS/TLS enabled
   - Should show the secure padlock icon and proper branding

3. **grafana-cold-start.png**
   - Grafana dashboard showing cold-start performance metrics
   - Should display p95 latency graph with 75s SLA line

4. **prometheus-rules.png**
   - Prometheus alert rules configuration page
   - Should show active alerts including ContactIngestRateZero

## How to Capture Screenshots

1. **Using alfred up command**:
   ```bash
   alfred up --profile core,bizdev
   ```

2. **Access services**:
   - Keycloak: https://keycloak.localtest.me
   - Grafana: http://localhost:3000
   - Prometheus: http://localhost:9090

3. **Capture screenshots**:
   - Use browser developer tools (F12) to set viewport to 1920x1080
   - Take full-page screenshots where appropriate
   - Save as PNG with descriptive filenames

4. **Post-processing**:
   - Ensure no sensitive data is visible
   - Add annotations if necessary to highlight key features
   - Optimize file size while maintaining quality
