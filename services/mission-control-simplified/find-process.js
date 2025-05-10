const { exec } = require('child_process');

// Find process using port 3007
exec('ps aux', (error, stdout, stderr) => {
  if (error) {
    console.error(`Error: ${error.message}`);
    return;
  }
  if (stderr) {
    console.error(`Stderr: ${stderr}`);
    return;
  }
  
  // Get all running processes
  const processes = stdout.split('\n');
  
  // Look for likely candidates
  const candidates = processes.filter(line => 
    line.includes('node') && 
    !line.includes('grep') && 
    !line.includes('find-process.js')
  );
  
  console.log('Potential processes that might be using port 3007:');
  candidates.forEach(process => {
    console.log(process);
  });
  
  console.log('\nAttempting to kill any Node.js processes started in our project directory...');
  
  // Try to kill processes that might be our server
  exec("ps aux | grep 'alfred-agent-platform.*server.js' | grep -v grep | awk '{print $2}' | xargs -r kill -9", (error, stdout, stderr) => {
    if (error) {
      console.error(`Error killing processes: ${error.message}`);
    } else {
      console.log('Attempted to kill matching processes');
    }
    
    // Now try to start a test server to see if the port is free
    exec('node -e "const http = require(\'http\'); const server = http.createServer(); server.on(\'error\', (e) => { console.log(\'Port 3007 is still in use\'); process.exit(1); }); server.listen(3007, () => { console.log(\'Port 3007 is now available\'); server.close(); });"', (error, stdout, stderr) => {
      if (error) {
        console.log(`Port 3007 is still in use. Error: ${error.message}`);
      } else {
        console.log(stdout);
      }
    });
  });
});