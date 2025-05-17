/**
 * GitHub Bridge MCP Server
 * 
 * This MCP server connects Claude Code to GitHub to enable
 * communication with ChatGPT or other AI systems.
 * 
 * Usage: 
 *   claude mcp add github-bridge -- node github-bridge-mcp.js
 * 
 * Environment variables:
 *   GITHUB_TOKEN - Personal access token with repo permissions
 *   REPO_OWNER - GitHub username or organization
 *   REPO_NAME - Repository name
 */

// Required dependencies:
// npm install @octokit/rest @anthropic-ai/mcp

const { Octokit } = require('@octokit/rest');
const { Server } = require('@anthropic-ai/mcp');

// GitHub configuration
const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const REPO_OWNER = process.env.REPO_OWNER || 'your-username';
const REPO_NAME = process.env.REPO_NAME || 'ai-bridge';
const CONVERSATION_FILE = 'conversation.md';

if (!GITHUB_TOKEN) {
  console.error('Error: GITHUB_TOKEN environment variable is required');
  process.exit(1);
}

// Initialize Octokit with your GitHub token
const octokit = new Octokit({
  auth: GITHUB_TOKEN,
});

const server = new Server({
  tools: [
    {
      name: 'getConversation',
      description: 'Get the current conversation from GitHub',
      parameters: {},
      handler: async () => {
        try {
          const response = await octokit.repos.getContent({
            owner: REPO_OWNER,
            repo: REPO_NAME,
            path: CONVERSATION_FILE,
          });
          
          const content = Buffer.from(response.data.content, 'base64').toString();
          return { content, sha: response.data.sha };
        } catch (error) {
          if (error.status === 404) {
            return { content: "# AI Conversation\n\nThis file contains an ongoing conversation between ChatGPT and Claude.", sha: null };
          }
          throw error;
        }
      }
    },
    {
      name: 'appendMessage',
      description: 'Append a message to the conversation in GitHub',
      parameters: {
        message: { type: 'string', description: 'Message to append' }
      },
      handler: async ({ message }) => {
        // First get the current content
        const { content, sha } = await server.tools.getConversation.handler({});
        
        // Format the message
        const timestamp = new Date().toISOString();
        const formattedMessage = `\n\n## Claude (${timestamp})\n\n${message}`;
        
        // Append the message
        const newContent = content + formattedMessage;
        
        // Update the file
        const response = await octokit.repos.createOrUpdateFileContents({
          owner: REPO_OWNER,
          repo: REPO_NAME,
          path: CONVERSATION_FILE,
          message: 'Claude message update',
          content: Buffer.from(newContent).toString('base64'),
          sha: sha,
        });
        
        return { success: true, sha: response.data.content.sha };
      }
    },
    {
      name: 'createGist',
      description: 'Create a new GitHub Gist for communication',
      parameters: {
        description: { type: 'string', description: 'Gist description' },
        initialMessage: { type: 'string', description: 'Initial message to include' }
      },
      handler: async ({ description, initialMessage }) => {
        const timestamp = new Date().toISOString();
        const content = `# AI Conversation\n\nStarted: ${timestamp}\n\n## Claude (${timestamp})\n\n${initialMessage}`;
        
        const response = await octokit.gists.create({
          description: description || 'AI Conversation',
          public: false,
          files: {
            'conversation.md': {
              content: content
            }
          }
        });
        
        return {
          gistId: response.data.id,
          gistUrl: response.data.html_url
        };
      }
    },
    {
      name: 'updateGist',
      description: 'Update an existing GitHub Gist',
      parameters: {
        gistId: { type: 'string', description: 'ID of the Gist to update' },
        message: { type: 'string', description: 'Message to append' }
      },
      handler: async ({ gistId, message }) => {
        // First get the current Gist
        const gist = await octokit.gists.get({ gist_id: gistId });
        
        // Get the content of conversation.md
        const filename = 'conversation.md';
        const currentContent = gist.data.files[filename]?.content || '';
        
        // Format the message
        const timestamp = new Date().toISOString();
        const formattedMessage = `\n\n## Claude (${timestamp})\n\n${message}`;
        
        // Append the message
        const newContent = currentContent + formattedMessage;
        
        // Update the Gist
        const response = await octokit.gists.update({
          gist_id: gistId,
          files: {
            [filename]: {
              content: newContent
            }
          }
        });
        
        return {
          success: true,
          gistUrl: response.data.html_url
        };
      }
    }
  ]
});

// Start the server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`GitHub Bridge MCP Server running on port ${PORT}`);
});