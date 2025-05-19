const { execSync } = require('child_process');

// Get all listening ports
try {
  console.log('Checking TCP ports with ss command...');
  const portsOutput = execSync('ss -tulpn').toString();

  // Check both ports 3007 and 3010
  console.log('Checking port 3007:');
  const port3007Lines = portsOutput.split('\n').filter(line => line.includes(':3007'));

  console.log('Checking port 3010:');
  const port3010Lines = portsOutput.split('\n').filter(line => line.includes(':3010'));

  // Check processes using port 3007
  if (port3007Lines.length > 0) {
    console.log('Found processes using port 3007:');
    port3007Lines.forEach(line => console.log(line));

    // Parse the process IDs from the output
    const pidMatches3007 = port3007Lines.map(line => {
      const match = line.match(/pid=(\d+)/);
      return match ? match[1] : null;
    }).filter(Boolean);

    if (pidMatches3007.length > 0) {
      console.log(`\nAttempting to kill processes on port 3007: ${pidMatches3007.join(', ')}`);

      for (const pid of pidMatches3007) {
        try {
          execSync(`kill -9 ${pid}`);
          console.log(`Successfully killed process ${pid}`);
        } catch (error) {
          console.error(`Failed to kill process ${pid}: ${error.message}`);
        }
      }
    }
  } else {
    console.log('No processes found using port 3007 with ss command.');
  }

  // Check processes using port 3010
  if (port3010Lines.length > 0) {
    console.log('Found processes using port 3010:');
    port3010Lines.forEach(line => console.log(line));

    // Parse the process IDs from the output
    const pidMatches3010 = port3010Lines.map(line => {
      const match = line.match(/pid=(\d+)/);
      return match ? match[1] : null;
    }).filter(Boolean);

    if (pidMatches3010.length > 0) {
      console.log(`\nAttempting to kill processes on port 3010: ${pidMatches3010.join(', ')}`);

      for (const pid of pidMatches3010) {
        try {
          execSync(`kill -9 ${pid}`);
          console.log(`Successfully killed process ${pid}`);
        } catch (error) {
          console.error(`Failed to kill process ${pid}: ${error.message}`);
        }
      }
    }
  } else {
    console.log('No processes found using port 3010 with ss command.');
  }
} catch (error) {
  console.log('ss command failed, trying another approach...');
  try {
    // Try with netstat if ss fails
    const netstatOutput = execSync('netstat -tulpn 2>/dev/null | grep 3007').toString();
    console.log('Netstat found:');
    console.log(netstatOutput);
  } catch (error) {
    console.log('Netstat command also failed. Try an alternative solution.');
  }
}

// Test if ports are now available
function testPort(port) {
  return new Promise((resolve, reject) => {
    console.log(`\nTesting if port ${port} is available...`);

    // Try to bind to the port
    const net = require('net');
    const testServer = net.createServer();

    testServer.once('error', (err) => {
      if (err.code === 'EADDRINUSE') {
        console.log(`Port ${port} is still in use by another process.`);
        resolve(false);
      } else {
        console.log(`Error testing port ${port}: ${err.message}`);
        resolve(false);
      }
    });

    testServer.once('listening', () => {
      console.log(`SUCCESS: Port ${port} is now available!`);
      testServer.close();
      resolve(true);
    });

    testServer.listen(port);
  });
}

// Test both ports
async function testPorts() {
  const port3007Available = await testPort(3007);
  const port3010Available = await testPort(3010);

  console.log('\nPORT STATUS SUMMARY:');
  console.log(`Port 3007: ${port3007Available ? 'AVAILABLE' : 'IN USE'}`);
  console.log(`Port 3010: ${port3010Available ? 'AVAILABLE' : 'IN USE'}`);

  // Exit with success if at least one port is available
  process.exit(port3007Available || port3010Available ? 0 : 1);
}

testPorts();
