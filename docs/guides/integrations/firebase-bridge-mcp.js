/**
 * Firebase Bridge MCP Server
 *
 * This MCP server connects Claude Code to a Firebase Realtime Database
 * to enable communication with ChatGPT or other AI systems.
 *
 * Usage:
 *   claude mcp add firebase-bridge -- node firebase-bridge-mcp.js
 */

// Required dependencies:
// npm install firebase @anthropic-ai/mcp

const { Server } = require('@anthropic-ai/mcp');
const firebase = require('firebase/app');
require('firebase/database');

// Initialize Firebase
const firebaseConfig = {
  // Your Firebase configuration - replace with actual values
  apiKey: "YOUR_API_KEY",
  authDomain: "your-project.firebaseapp.com",
  databaseURL: "https://your-project-default-rtdb.firebaseio.com",
  projectId: "your-project",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "your-messaging-id",
  appId: "your-app-id"
};

firebase.initializeApp(firebaseConfig);
const db = firebase.database();
const messagesRef = db.ref('ai_messages');

const server = new Server({
  tools: [
    {
      name: 'getAllMessages',
      description: 'Get all messages in the conversation',
      parameters: {},
      handler: async () => {
        const snapshot = await messagesRef.once('value');
        const messages = [];
        snapshot.forEach(child => {
          messages.push({
            id: child.key,
            ...child.val()
          });
        });
        return { messages };
      }
    },
    {
      name: 'sendMessage',
      description: 'Send a message to the conversation',
      parameters: {
        content: { type: 'string', description: 'Message content' }
      },
      handler: async ({ content }) => {
        await messagesRef.push({
          from: 'claude',
          content,
          timestamp: Date.now()
        });
        return { success: true };
      }
    },
    {
      name: 'getNewMessages',
      description: 'Get messages newer than a specific timestamp',
      parameters: {
        since: { type: 'number', description: 'Timestamp to get messages after' }
      },
      handler: async ({ since }) => {
        const snapshot = await messagesRef.orderByChild('timestamp').startAfter(since).once('value');
        const messages = [];
        snapshot.forEach(child => {
          messages.push({
            id: child.key,
            ...child.val()
          });
        });
        return { messages };
      }
    },
    {
      name: 'clearAllMessages',
      description: 'Clear all messages in the conversation',
      parameters: {},
      handler: async () => {
        await messagesRef.remove();
        return { success: true };
      }
    }
  ]
});

// Start the server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Firebase Bridge MCP Server running on port ${PORT}`);
});
