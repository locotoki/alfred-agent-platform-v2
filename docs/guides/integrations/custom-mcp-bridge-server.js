/**
 * Custom MCP Bridge Server
 * 
 * This server provides both a REST API for ChatGPT and an MCP interface for Claude Code,
 * allowing them to communicate with each other.
 * 
 * Usage:
 *   1. Start this server: node custom-mcp-bridge-server.js
 *   2. Add to Claude Code: claude mcp add custom-bridge -- node custom-mcp-bridge-server.js
 *   3. Direct ChatGPT to the web interface (typically http://localhost:3000/chatgpt.html)
 */

// Required dependencies:
// npm install express cors @anthropic-ai/mcp

const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { Server } = require('@anthropic-ai/mcp');

// Create Express app
const app = express();
app.use(cors());
app.use(express.json());

// Message storage
const messages = [];

// API endpoints for ChatGPT
app.get('/messages', (req, res) => {
  const since = req.query.since ? parseInt(req.query.since) : 0;
  const filteredMessages = messages.filter(m => m.timestamp > since);
  res.json(filteredMessages);
});

app.post('/messages', (req, res) => {
  const { content } = req.body;
  if (!content) {
    return res.status(400).json({ error: 'Content is required' });
  }
  
  const message = {
    id: messages.length + 1,
    from: 'chatgpt',
    content,
    timestamp: Date.now()
  };
  
  messages.push(message);
  res.status(201).json(message);
});

// Serve the ChatGPT interface
app.get('/chatgpt.html', (req, res) => {
  const htmlContent = `
<!DOCTYPE html>
<html>
<head>
  <title>AI Bridge</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
    .message { margin-bottom: 10px; padding: 8px; border-radius: 4px; }
    .chatgpt { background-color: #f0f8ff; border-left: 4px solid #0070f3; }
    .claude { background-color: #f5f5dc; border-left: 4px solid #8e44ad; }
    pre { white-space: pre-wrap; margin: 0; }
    h1, h2 { color: #333; }
    textarea { width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px; }
    button { background: #0070f3; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; }
    button:hover { background: #0051a2; }
    #messageLog { margin-top: 20px; border-top: 1px solid #eee; padding-top: 20px; }
    .timestamp { font-size: 0.8em; color: #777; }
  </style>
</head>
<body>
  <h1>AI Communication Bridge</h1>
  
  <div>
    <h2>Send Message as ChatGPT</h2>
    <textarea id="messageInput" rows="4" placeholder="Type your message here..."></textarea>
    <br><br>
    <button id="sendBtn">Send Message</button>
  </div>
  
  <div>
    <h2>Conversation</h2>
    <div id="messageLog"></div>
  </div>

  <script>
    // API URL - change if needed
    const API_URL = window.location.origin;
    let lastTimestamp = 0;
    
    // Send message
    document.getElementById('sendBtn').addEventListener('click', async function() {
      const content = document.getElementById('messageInput').value;
      if (content.trim() === '') return;
      
      try {
        const response = await fetch(\`\${API_URL}/messages\`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ content })
        });
        
        if (!response.ok) throw new Error('Failed to send message');
        
        document.getElementById('messageInput').value = '';
        await fetchMessages();
      } catch (error) {
        console.error('Error sending message:', error);
        alert('Failed to send message: ' + error.message);
      }
    });
    
    // Fetch messages
    async function fetchMessages() {
      try {
        const response = await fetch(\`\${API_URL}/messages?since=\${lastTimestamp}\`);
        if (!response.ok) throw new Error('Failed to fetch messages');
        
        const newMessages = await response.json();
        
        if (newMessages.length > 0) {
          // Update lastTimestamp to the most recent message
          lastTimestamp = Math.max(...newMessages.map(m => m.timestamp));
          
          // Add messages to the log
          const messageLog = document.getElementById('messageLog');
          newMessages.forEach(message => {
            const messageEl = document.createElement('div');
            messageEl.className = 'message ' + message.from;
            messageEl.innerHTML = \`
              <strong>\${message.from === 'chatgpt' ? 'ChatGPT' : 'Claude'}</strong> 
              <span class="timestamp">(\${new Date(message.timestamp).toLocaleTimeString()})</span>:
              <pre>\${message.content}</pre>
            \`;
            messageLog.appendChild(messageEl);
          });
          
          // Scroll to bottom
          window.scrollTo(0, document.body.scrollHeight);
        }
      } catch (error) {
        console.error('Error fetching messages:', error);
      }
    }
    
    // Poll for new messages every 3 seconds
    setInterval(fetchMessages, 3000);
    
    // Initial fetch
    fetchMessages();
    
    // Add keypress handler for textarea
    document.getElementById('messageInput').addEventListener('keypress', function(e) {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        document.getElementById('sendBtn').click();
      }
    });
  </script>
</body>
</html>
  `;
  
  res.send(htmlContent);
});

// Default route
app.get('/', (req, res) => {
  res.redirect('/chatgpt.html');
});

// Start HTTP server
const HTTP_PORT = process.env.HTTP_PORT || 3000;
const httpServer = app.listen(HTTP_PORT, () => {
  console.log(`HTTP API server running on port ${HTTP_PORT}`);
  console.log(`ChatGPT interface available at: http://localhost:${HTTP_PORT}/chatgpt.html`);
});

// Create MCP server
const mcpServer = new Server({
  tools: [
    {
      name: 'getMessages',
      description: 'Get all messages or messages after a timestamp',
      parameters: {
        since: { type: 'number', description: 'Optional timestamp to filter messages', required: false }
      },
      handler: async ({ since = 0 }) => {
        const filteredMessages = messages.filter(m => m.timestamp > since);
        return { messages: filteredMessages };
      }
    },
    {
      name: 'sendMessage',
      description: 'Send a message from Claude',
      parameters: {
        content: { type: 'string', description: 'Message content' }
      },
      handler: async ({ content }) => {
        const message = {
          id: messages.length + 1,
          from: 'claude',
          content,
          timestamp: Date.now()
        };
        
        messages.push(message);
        return { success: true, messageId: message.id };
      }
    },
    {
      name: 'clearMessages',
      description: 'Clear all messages in the conversation',
      parameters: {},
      handler: async () => {
        messages.length = 0;
        return { success: true };
      }
    },
    {
      name: 'getServerInfo',
      description: 'Get information about the bridge server',
      parameters: {},
      handler: async () => {
        return {
          httpServerUrl: `http://localhost:${HTTP_PORT}`,
          chatgptInterface: `http://localhost:${HTTP_PORT}/chatgpt.html`,
          messageCount: messages.length,
          serverStartTime: httpServer.startTime || new Date().toISOString()
        };
      }
    }
  ]
});

// Start MCP server
const MCP_PORT = process.env.MCP_PORT || 3001;
mcpServer.listen(MCP_PORT, () => {
  console.log(`MCP server running on port ${MCP_PORT}`);
});