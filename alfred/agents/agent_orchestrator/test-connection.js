// Simple script to test connectivity to social-intel service
import fetch from 'node-fetch';

async function testConnection() {
  const urls = [
    'http://social-intel:9000/health/',
    'http://social-intel:9000/health',
    'http://localhost:9000/health/',
    'http://localhost:9000/health'
  ];

  console.log('Trying to connect to social-intel service...');

  for (const url of urls) {
    try {
      console.log(`Testing: ${url}`);
      const response = await fetch(url, { timeout: 5000 });
      const data = await response.json();
      console.log(`Success! Response from ${url}:`, data);
      return true;
    } catch (error) {
      console.error(`Error connecting to ${url}:`, error.message);
    }
  }

  console.error('All connection attempts failed');
  return false;
}

testConnection();
