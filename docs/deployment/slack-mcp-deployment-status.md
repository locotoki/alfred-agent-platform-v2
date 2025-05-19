# Slack MCP Gateway Deployment Status

## Current Status
- ✅ Implementation complete (PR #55)
- ✅ .env.example added for security (PR #57)
- ✅ Deploy workflow fixed (PR #58, #59)
- ✅ Images successfully pushed to GHCR
- ✅ Deployment documentation complete (PR #60)
- 🔄 Ready for staging deployment

## Docker Images Available
- `ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:17482304b0fb9a802bf6a58ae89ea2751afc0b7e`
- `ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:latest`

## Next Steps

1. **Ensure Environment Variables are Set**
   ```bash
   export SLACK_APP_TOKEN="xapp-1-..."
   export SLACK_BOT_TOKEN="xoxb-..."
   ```

2. **Deploy to Staging**
   ```bash
   ./scripts/deploy-slack-mcp-staging.sh \
     --image ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:17482304b0fb9a802bf6a58ae89ea2751afc0b7e
   ```

3. **Smoke Test**
   - Send `/alfred ping` in Slack channel where bot is present
   - Check logs: `kubectl -n alfred-staging logs -l app=slack-mcp-gateway`

4. **Monitor 24-hour Canary**
   - Watch alerts in #alerts-staging
   - Monitor Prometheus dashboards
   - Check application logs periodically

5. **Production Deployment** (after successful canary)
   ```bash
   # Tag for production
   docker tag [digest] ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:v0.1.0
   docker push ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:v0.1.0

   # Deploy to production
   helm upgrade -f charts/slack-mcp-gateway/values-prod.yaml ...
   ```

## Deployment Script Updated
The deployment script now accepts an `--image` parameter to specify the exact image to deploy:
```bash
./scripts/deploy-slack-mcp-staging.sh --image [IMAGE_URL]
```

If no image is specified, it defaults to the latest commit SHA on the current branch.
