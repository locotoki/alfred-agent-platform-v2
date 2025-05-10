const http = require('http');
const fs = require('fs');
const path = require('path');
const https = require('https');
const fetch = require('node-fetch');

const PORT = 8090;

const server = http.createServer(async (req, res) => {
  console.log(`Request received: ${req.url}`);
  
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }
  
  // Handle API proxy request
  if (req.url === '/api/run-analysis') {
    if (req.method === 'POST') {
      try {
        console.log('Proxying API request to social-intel service...');
        
        const response = await fetch('http://localhost:9000/api/youtube/niche-scout', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            category: 'kids',
            subcategory: 'kids.nursery'
          })
        });
        
        const data = await response.json();
        console.log('API response received:', data);
        
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(data));
      } catch (error) {
        console.error('API proxy error:', error);
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: error.message }));
      }
      return;
    }
  }
  
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