# Slack Integration Operations Runbook

## 🚨 Incident Response Procedures

### Symptom: Slack Commands Not Responding

#### 1. Verify Service Health
```bash
# Check all services are running
docker-compose ps | grep -E "slack_mcp_gateway|echo-agent|redis"

# Expected output:
# redis                running (healthy)   0.0.0.0:6379->6379/tcp
# slack_mcp_gateway    running (healthy)   0.0.0.0:3010->3000/tcp
# echo-agent           running
```

#### 2. Check Gateway Logs
```bash
# Look for connection status
docker logs slack_mcp_gateway --tail 50 | grep -E "Connected|Error|SLACK"

# Good signs:
# "Connected to Slack"
# "Connected to Redis"
# "Slack MCP Gateway started successfully"

# Bad signs:
# "invalid_auth"
# "Redis connection error"
# "SLACK_APP_TOKEN and/or SLACK_BOT_TOKEN"
```

#### 3. Verify Redis Connectivity
```bash
# Test Redis auth
docker exec redis redis-cli -a $REDIS_PASSWORD ping
# Expected: PONG

# Check streams exist
docker exec redis redis-cli -a $REDIS_PASSWORD EXISTS mcp.requests mcp.responses
# Expected: 2
```

#### 4. Check Message Flow
```bash
# Count pending messages
docker exec redis redis-cli -a $REDIS_PASSWORD XLEN mcp.requests

# Check consumer groups
docker exec redis redis-cli -a $REDIS_PASSWORD XINFO GROUPS mcp.requests

# View recent messages
docker exec redis redis-cli -a $REDIS_PASSWORD XREVRANGE mcp.requests + - COUNT 5
```

### Symptom: "No metadata found for request" Errors

This indicates responses arriving for expired request metadata.

#### Resolution:
```bash
# Check for old unprocessed messages
docker exec redis redis-cli -a $REDIS_PASSWORD XPENDING mcp.responses slack-gateway

# Clear old messages if needed
docker exec redis redis-cli -a $REDIS_PASSWORD XTRIM mcp.responses MAXLEN 1000
```

### Symptom: Redis Authentication Failures

#### 1. Verify Environment Variables
```bash
# Check Redis password is set
echo $REDIS_PASSWORD | wc -c  # Should be > 1

# Verify in docker-compose.override.yml
grep REDIS_PASSWORD docker-compose.override.yml
```

#### 2. Test Direct Connection
```bash
# Try connecting with password
docker exec -it redis redis-cli -a $REDIS_PASSWORD INFO server

# If fails, check Redis config
docker exec redis cat /usr/local/etc/redis/redis.conf | grep requirepass
```

### Symptom: High Memory Usage / Message Backlog

#### 1. Check Queue Sizes
```bash
# Monitor stream lengths
watch -n 5 'docker exec redis redis-cli -a $REDIS_PASSWORD INFO memory | grep used_memory_human'

# Check message counts
docker exec redis redis-cli -a $REDIS_PASSWORD EVAL "
  return {
    requests = redis.call('XLEN', 'mcp.requests'),
    responses = redis.call('XLEN', 'mcp.responses')
  }
" 0
```

#### 2. Trim Old Messages
```bash
# Keep only last 10k messages
docker exec redis redis-cli -a $REDIS_PASSWORD XTRIM mcp.requests MAXLEN ~ 10000
docker exec redis redis-cli -a $REDIS_PASSWORD XTRIM mcp.responses MAXLEN ~ 10000
```

## 📊 Monitoring Commands

### Real-time Dashboard
```bash
# Create monitoring script
cat > monitor-slack.sh << 'EOF'
#!/bin/bash
while true; do
  clear
  echo "=== Slack Integration Monitor ==="
  echo "Time: $(date)"
  echo ""
  echo "=== Service Status ==="
  docker-compose ps | grep -E "slack_mcp_gateway|echo-agent|redis" | awk '{print $1,$3,$4}'
  echo ""
  echo "=== Queue Sizes ==="
  docker exec redis redis-cli -a $REDIS_PASSWORD --no-auth-warning EVAL "
    return 'Requests: ' .. redis.call('XLEN', 'mcp.requests') ..
           ', Responses: ' .. redis.call('XLEN', 'mcp.responses')
  " 0
  echo ""
  echo "=== Recent Activity ==="
  docker logs slack_mcp_gateway --tail 5 2>&1 | grep -E "command|response"
  sleep 5
done
EOF

chmod +x monitor-slack.sh
./monitor-slack.sh
```

### Performance Metrics
```bash
# Message processing rate
docker exec redis redis-cli -a $REDIS_PASSWORD --no-auth-warning EVAL "
  local info = {}
  for _, stream in ipairs({'mcp.requests', 'mcp.responses'}) do
    local groups = redis.call('XINFO', 'GROUPS', stream)
    for i = 1, #groups, 1 do
      local group = groups[i]
      info[stream .. ':' .. group[2]] = {
        consumers = group[4],
        pending = group[6],
        last_id = group[8]
      }
    end
  end
  return cjson.encode(info)
" 0 | jq .
```

## 🔧 Maintenance Procedures

### Scheduled Restart
```bash
# Graceful restart with zero downtime
docker-compose stop echo-agent
docker-compose stop slack_mcp_gateway
docker-compose up -d slack_mcp_gateway
sleep 5
docker-compose up -d echo-agent
```

### Log Rotation
```bash
# Truncate large logs
docker exec slack_mcp_gateway sh -c 'echo > /proc/1/fd/1'
docker exec echo-agent sh -c 'echo > /proc/1/fd/1'
```

### Consumer Group Reset
```bash
# If messages are stuck/corrupted
SERVICE="echo-agent"
STREAM="mcp.requests"
GROUP="echo-agent"

# Stop consumer
docker-compose stop $SERVICE

# Delete and recreate group
docker exec redis redis-cli -a $REDIS_PASSWORD XGROUP DESTROY $STREAM $GROUP
docker exec redis redis-cli -a $REDIS_PASSWORD XGROUP CREATE $STREAM $GROUP $ MKSTREAM

# Restart consumer
docker-compose up -d $SERVICE
```

## 🔐 Security Checks

### Daily Security Audit
```bash
# Check for unauthorized Redis commands
docker logs redis --since 24h | grep -E "SLAVEOF|CONFIG|MODULE|FLUSHDB|FLUSHALL"

# Verify Redis is not exposed
netstat -tlnp | grep 6379  # Should only show docker-proxy

# Check Slack token validity
docker exec slack_mcp_gateway wget -qO- http://localhost:3010/health | jq .services.slack
```

### Credential Rotation Procedure
```bash
# 1. Generate new tokens in Slack app settings
# 2. Update .env file
# 3. Restart services
docker-compose restart slack_mcp_gateway echo-agent
# 4. Verify connectivity
docker logs slack_mcp_gateway --tail 20 | grep "Connected to Slack"
```

## 📈 Capacity Planning

### Storage Requirements
- Redis memory: ~1KB per message
- Retention: 1 hour metadata + message TTL
- Estimate: 1000 msgs/hour = ~1MB/hour

### Scaling Considerations
- Multiple echo agents: Use different consumer names
- High volume: Increase Redis memory limit
- Geographic distribution: Redis Cluster mode

## 🚀 Emergency Procedures

### Complete Reset
```bash
# WARNING: This deletes all messages!
docker-compose down
docker volume rm alfred-agent-platform-v2_redis-data
docker-compose up -d redis slack_mcp_gateway echo-agent
```

### Failover to Backup
```bash
# If primary Redis fails
# 1. Update REDIS_URL in .env to backup instance
# 2. Restart all services
docker-compose restart slack_mcp_gateway echo-agent
```

### Debug Mode
```bash
# Enable verbose logging
docker-compose stop slack_mcp_gateway
docker run -it --rm \
  --network alfred-network \
  -e LOG_LEVEL=debug \
  -e SLACK_APP_TOKEN=$SLACK_APP_TOKEN \
  -e SLACK_BOT_TOKEN=$SLACK_BOT_TOKEN \
  -e REDIS_URL=redis://:$REDIS_PASSWORD@redis:6379 \
  slack-mcp-gateway:latest
```

## 📞 Escalation Matrix

| Issue | First Response | Escalation | Time Limit |
|-------|---------------|------------|------------|
| Commands not working | Check logs & connections | DevOps on-call | 15 min |
| Redis down | Restart container | Database team | 5 min |
| Auth failures | Verify credentials | Security team | 10 min |
| High memory | Trim streams | Platform team | 30 min |
| Data loss | Check backups | Leadership | Immediate |

## 📋 Post-Incident Checklist

- [ ] Services restored and verified working
- [ ] Root cause identified
- [ ] Logs collected and archived
- [ ] Metrics captured for duration
- [ ] Security audit if auth-related
- [ ] Documentation updated
- [ ] Team debriefed
- [ ] Monitoring improved
