// Custom server script to start Next.js development server
const { spawn } = require('child_process');
const path = require('path');

console.log('Starting Next.js development server on port 3007');

// Set environment variables
process.env.NODE_ENV = 'development';
process.env.PORT = '3007';

// Start Next.js development server
const nextDev = spawn('npx', ['next', 'dev', '-p', '3007'], {
  stdio: 'inherit',
  shell: true,
  cwd: __dirname
});

// Log process ID for tracking
console.log(`Server started with PID: ${nextDev.pid}`);

// Handle process events
nextDev.on('error', (err) => {
  console.error('Failed to start server:', err);
});

nextDev.on('close', (code) => {
  console.log(`Server process exited with code ${code}`);
});

// Keep the process running
process.on('SIGINT', () => {
  console.log('Shutting down server...');
  nextDev.kill('SIGINT');
  process.exit(0);
});
