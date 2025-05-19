const { exec } = require('child_process');

// Try to get more information about what's using port 3007
exec('ss -tulpn | grep ":3007"', (error, stdout, stderr) => {
  console.log('Checking what process is using port 3007...');

  if (error) {
    console.error(`Error: ${error.message}`);
    console.log('Trying alternative approach...');

    // Try netstat if ss doesn't work
    exec('netstat -tulpn 2>/dev/null | grep ":3007"', (error2, stdout2, stderr2) => {
      if (error2) {
        console.error(`Netstat error: ${error2.message}`);
      } else {
        console.log('Netstat output:');
        console.log(stdout2);
      }
    });

    return;
  }

  console.log('SS output:');
  console.log(stdout);

  // Try to get more process details
  if (stdout) {
    const pidMatch = stdout.match(/pid=(\d+)/);
    const pid = pidMatch ? pidMatch[1] : null;

    if (pid) {
      console.log(`\nProcess ID found: ${pid}`);
      console.log('Getting process details...');

      exec(`ps -p ${pid} -o pid,ppid,cmd,%cpu,%mem`, (error, stdout, stderr) => {
        if (error) {
          console.error(`Error getting process details: ${error.message}`);
        } else {
          console.log('Process details:');
          console.log(stdout);
        }
      });
    }
  }
});
