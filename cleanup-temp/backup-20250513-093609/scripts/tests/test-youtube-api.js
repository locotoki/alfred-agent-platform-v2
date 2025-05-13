const http = require('http');

console.log('Testing Niche Scout API...');

const options = {
  hostname: 'localhost',
  port: 9000,
  path: '/api/youtube/niche-scout',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  }
};

const req = http.request(options, (res) => {
  console.log(`STATUS: ${res.statusCode}`);
  console.log('HEADERS:', res.headers);
  
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('BODY:', data.slice(0, 300) + '...');
    
    try {
      const jsonResponse = JSON.parse(data);
      console.log('Number of niches:', jsonResponse.niches?.length || 0);
      
      if (jsonResponse.niches?.length > 0) {
        console.log('First niche name:', jsonResponse.niches[0].name);
        console.log('First niche growth rate:', jsonResponse.niches[0].growth_rate);
      }
      
      console.log('Analysis summary:', jsonResponse.analysis_summary);
    } catch (e) {
      console.error('Error parsing JSON:', e);
    }
    
    console.log('API test completed.');
  });
});

req.on('error', (e) => {
  console.error(`Problem with request: ${e.message}`);
});

// Write data to request body
const postData = JSON.stringify({
  category: 'kids',
  subcategory: 'kids.nursery'
});

req.write(postData);
req.end();