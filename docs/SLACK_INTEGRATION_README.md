# Slack Integration Documentation

This directory contains comprehensive documentation for the Alfred platform's Slack integration.

## 📚 Documentation Structure

### For Users & Operators
- **[Quick Start Guide](./slack-integration-quickstart.md)** - Get up and running in 5 minutes
- **[Operations Runbook](./slack-integration-ops-runbook.md)** - Incident response, monitoring, maintenance

### For Developers
- **[Architecture Guide](./slack-integration-architecture.md)** - Complete technical architecture
- **[Developer Guide](./slack-integration-developer-guide.md)** - Build your own agents

### Security & Incidents
- **[Security Incident RCA](./security/2025-05-28-redis-slaveout.md)** - Redis compromise incident and fixes

## 🚀 Quick Commands

```bash
# Start Slack integration
docker-compose up -d redis slack_mcp_gateway echo-agent

# Test in Slack
/alfred health
/alfred ping hello world

# Check health
curl http://localhost:3010/health
docker logs echo-agent --tail 20
```

## 🏗️ Architecture Overview

```
┌─────────┐     ┌──────────────────┐     ┌─────────────┐     ┌────────────┐
│  Slack  │────▶│ slack_mcp_gateway│────▶│Redis Stream │────▶│   Agents   │
│  Users  │◀────│   (Node.js)      │◀────│(mcp.req/res)│◀────│(echo,etc.) │
└─────────┘     └──────────────────┘     └─────────────┘     └────────────┘
```

## 🔧 Key Components

| Component | Purpose | Port | Health Check |
|-----------|---------|------|--------------|
| `slack_mcp_gateway` | Slack ↔ Redis bridge | 3010 | `/health` |
| `echo-agent` | Example command processor | - | Logs only |
| Redis | Message broker | 6379 | `redis-cli ping` |

## 🔒 Security Features

- ✅ Redis authentication required
- ✅ Dangerous Redis commands disabled
- ✅ Socket Mode (no public webhooks)
- ✅ Token rotation support
- ✅ Falco monitoring rules
- ✅ Nightly vulnerability scans

## 📊 Available Commands

| Command | Response | Handler |
|---------|----------|---------|
| `/alfred health` | ✅ Echo agent is healthy! | echo-agent |
| `/alfred ping [msg]` | 🏓 [msg] | echo-agent |
| `/alfred [other]` | Echo agent received: [other] | echo-agent |

## 🚨 Common Issues

| Issue | Solution | Details |
|-------|----------|---------|
| No response in Slack | Check gateway logs | [Ops Runbook](./slack-integration-ops-runbook.md#symptom-slack-commands-not-responding) |
| Redis auth errors | Verify REDIS_PASSWORD | [Quick Start](./slack-integration-quickstart.md#redis-connection-errors) |
| "No metadata found" | Normal for old messages | [Architecture](./slack-integration-architecture.md#troubleshooting) |

## 📝 Environment Variables

```bash
# Required for Slack
SLACK_APP_TOKEN=xapp-1-...     # Socket Mode connection
SLACK_BOT_TOKEN=xoxb-...       # Bot authentication

# Required for Redis
REDIS_PASSWORD=your-password    # No default, must be set
```

## 🔄 Message Flow Example

```
1. User: /alfred health
2. Slack → Gateway: Receives slash command
3. Gateway → Redis: Publishes to mcp.requests
4. Echo Agent: Consumes message
5. Echo Agent → Redis: Publishes to mcp.responses
6. Gateway → Slack: "✅ Echo agent is healthy!"
```

## 🧪 Testing

```bash
# Manual test via Redis
docker exec redis redis-cli -a $REDIS_PASSWORD \
  XADD mcp.requests '*' \
  id test-123 type slack_command \
  command /alfred text "ping test"

# Check response
docker exec redis redis-cli -a $REDIS_PASSWORD \
  XRANGE mcp.responses - +
```

## 📈 Monitoring

- Prometheus metrics: Port 9091 on each service
- Health endpoints: See component table above
- Logs: `docker-compose logs -f [service]`
- Real-time monitor: See [Ops Runbook](./slack-integration-ops-runbook.md#real-time-dashboard)

## 🔗 Related Documentation

- [Service README](../services/slack_mcp_gateway/README.md) - Gateway implementation details
- [Echo Agent Source](../services/slack_mcp_gateway/echo_agent.py) - Example agent code
- [Docker Compose](../docker-compose.override.yml) - Service configuration

---

For questions or issues, check the [Operations Runbook](./slack-integration-ops-runbook.md) first, then reach out to the platform team.
