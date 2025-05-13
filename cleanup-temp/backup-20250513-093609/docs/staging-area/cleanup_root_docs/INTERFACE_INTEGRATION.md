# Alfred Interface Integration Guide

This document explains how to integrate and use the multiple interface options for interacting with the Alfred Agent Platform.

## Available Interfaces

Alfred Agent Platform provides two primary interface options:

1. **Slack Bot Interface**: Interact with Alfred directly from your Slack workspace
2. **Streamlit Chat UI**: Web-based chat interface for interacting with Alfred

Both interfaces provide similar functionality while serving different use cases and environments.

## Comparison of Interfaces

| Feature | Slack Bot | Streamlit Chat UI |
|---------|-----------|-------------------|
| Environment | Slack workspaces | Web browser |
| Authentication | Via Slack | None (network control) |
| Commands | Full command support | Full command support |
| Rich Messages | Block Kit format | Markdown format |
| File Handling | Limited support | Not supported |
| Conversation Threading | Supported | Linear chat history |
| Multi-user Support | Team-wide access | Single user per session |
| Ideal Use Case | Team collaboration | Development, testing, demos |

## Setup Instructions

### Slack Bot Setup

1. Set up Slack Bot credentials as described in `SLACK_BOT_SETUP.md`
2. Configure environment variables:
   ```
   SLACK_BOT_TOKEN=xoxb-your-token
   SLACK_SIGNING_SECRET=your-signing-secret
   ```
3. Start the Slack Bot service:
   ```bash
   cd services/alfred-bot
   ./start-slackbot-dev.sh
   ```

### Streamlit Chat UI Setup

1. Ensure Alfred Bot API is running
2. Configure environment variables:
   ```
   ALFRED_API_URL=http://localhost:8011
   ```
3. Start the Streamlit Chat UI:
   ```bash
   cd services/streamlit-chat
   ./start-dev.sh
   ```

### Combined Setup (Development)

To run both interfaces in development mode:

```bash
cd services/streamlit-chat
./start-dev-stack.sh
```

### Docker Compose Setup (Production)

To run both interfaces in a Docker environment:

```bash
cd services/streamlit-chat
docker-compose up -d
```

## Unified Command Reference

Both interfaces support the same core commands:

- `help` - Show available commands
- `ping` - Test bot responsiveness
- `trend <topic>` - Analyze trends for a topic
- `status <task_id>` - Check task status
- `cancel <task_id>` - Cancel a running task

## Integration Scenarios

### Scenario 1: Development and Testing

**Use Case**: Developers need to test Alfred's functionality during development.

**Solution**: Use the Streamlit Chat UI during development to test commands and workflow implementation without requiring Slack credentials. The interface provides debug mode to inspect API calls.

### Scenario 2: Team Collaboration

**Use Case**: Marketing team needs to collaborate on trend analysis for various topics.

**Solution**: Use the Slack Bot interface for team-wide access. Team members can use `/alfred trend` commands and view the results in shared channels, leveraging Slack's threading for organized discussions.

### Scenario 3: Demos and Presentations

**Use Case**: Demonstrating Alfred's capabilities to stakeholders.

**Solution**: Use the Streamlit Chat UI for a clean, focused interface that highlights Alfred's core capabilities without the distraction of a full Slack interface. The web UI provides a more controlled environment for demos.

### Scenario 4: Backup Interface

**Use Case**: Slack is temporarily unavailable, but users need to interact with Alfred.

**Solution**: Direct users to the Streamlit Chat UI as a backup interface. They can continue using the same commands they're familiar with from Slack.

## Cross-Interface Task Tracking

Tasks created in either interface can be tracked in both interfaces:

1. Start a trend analysis in Slack: `/alfred trend artificial intelligence`
2. Note the Task ID in the response
3. Check the task status in Streamlit Chat UI: `status <task_id>`

This works because both interfaces communicate with the same backend services through the Alfred Bot API.

## Best Practices

1. **User Training**: Train users on core commands that work consistently across both interfaces
2. **Documentation**: Maintain a central command reference for users
3. **Environment Variables**: Use environment variable files to maintain consistent configuration
4. **Health Monitoring**: Regularly check both interfaces with ping commands
5. **Security**: Secure the Streamlit Chat UI with proper network controls since it lacks authentication

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Slack Bot not responding | Check Slack API credentials and ngrok tunnel status |
| Streamlit Chat UI cannot connect to Alfred | Verify Alfred Bot API is running and URL is correct |
| Task results not appearing | Check task ID is correct and task processing is complete |

## Further Resources

- [Alfred Bot Documentation](services/alfred-bot/README.md)
- [Streamlit Chat UI Documentation](services/streamlit-chat/README.md)
- [Slack API Documentation](https://api.slack.com/docs)
- [Streamlit Documentation](https://docs.streamlit.io/)