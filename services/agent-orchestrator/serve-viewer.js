const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8090;

const server = http.createServer((req, res) => {
  console.log(`Request received: ${req.url}`);
  
  // Serve the viewer HTML file
  if (req.url === '/' || req.url === '/index.html') {
    fs.readFile(path.join(__dirname, 'view-results.html'), (err, data) => {
      if (err) {
        res.writeHead(500);
        res.end('Error loading viewer');
        return;
      }
      
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(data);
    });
    return;
  }
  
  // Serve the demo script
  if (req.url === '/add-demo-results.js') {
    fs.readFile(path.join(__dirname, 'add-demo-results.js'), (err, data) => {
      if (err) {
        res.writeHead(500);
        res.end('Error loading script');
        return;
      }
      
      res.writeHead(200, { 'Content-Type': 'application/javascript' });
      res.end(data);
    });
    return;
  }
  
  // 404 for everything else
  res.writeHead(404);
  res.end('Not found');
});

server.listen(PORT, () => {
  console.log(`Results viewer server running at http://localhost:${PORT}/`);
});