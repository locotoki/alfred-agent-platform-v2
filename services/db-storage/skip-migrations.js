// Skip migrations script
const { spawn } = require('child_process');
const path = require('path');

console.log('Starting storage-api service without migrations...');

// Set environment variable to skip migrations
process.env.SKIP_MIGRATIONS = 'true';
process.env.PGRST_JWT_SECRET = process.env.JWT_SECRET || 'super-secret-jwt-token';

// Path to original server.js
const serverPath = path.join('/app', 'dist', 'server.js');

// Start the original server process
const serverProcess = spawn('node', [serverPath], {
  stdio: 'inherit',
  env: process.env
});

// Handle process events
serverProcess.on('error', (err) => {
  console.error('Failed to start server process:', err);
  process.exit(1);
});

serverProcess.on('exit', (code, signal) => {
  if (code !== 0) {
    console.error(`Server process exited with code ${code} and signal ${signal}`);
    process.exit(code || 1);
  }
  process.exit(0);
});

// Handle termination signals
['SIGINT', 'SIGTERM'].forEach((signal) => {
  process.on(signal, () => {
    console.log(`Received ${signal}, terminating child process...`);
    serverProcess.kill(signal);
  });
});