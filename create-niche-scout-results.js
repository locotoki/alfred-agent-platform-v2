const http = require('http');
const fs = require('fs');

console.log('Fetching Niche Scout data and creating results file...');

// Make the API request
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
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    try {
      const apiResponse = JSON.parse(data);
      console.log('API response received successfully');
      
      // Transform to NicheScoutResult format
      const nicheScoutResult = {
        run_date: new Date().toISOString(),
        trending_niches: apiResponse.niches.map((niche, index) => ({
          query: niche.name,
          view_sum: Math.round(niche.growth_rate * 10000),
          rsv: niche.growth_rate,
          view_rank: index + 1,
          rsv_rank: index + 1,
          score: niche.growth_rate,
          x: (index % 5) * 2 - 5,
          y: Math.floor(index / 5) * 2 - 2,
          niche: Math.floor(index / 3)
        })),
        top_niches: apiResponse.niches.slice(0, 5).map((niche, index) => ({
          query: niche.name,
          view_sum: Math.round(niche.growth_rate * 10000),
          rsv: niche.growth_rate,
          view_rank: index + 1,
          rsv_rank: index + 1,
          score: niche.growth_rate,
          x: (index % 5) * 2 - 5,
          y: Math.floor(index / 5) * 2 - 2,
          niche: Math.floor(index / 3)
        })),
        actual_cost: 95.50,
        actual_processing_time: 120.5
      };
      
      // Write to file
      const resultsPath = './niche-scout-results.json';
      fs.writeFileSync(resultsPath, JSON.stringify(nicheScoutResult, null, 2));
      
      console.log(`Results written to ${resultsPath}`);
      console.log('To view these results:');
      console.log('1. Open the viewer at http://localhost:8090/');
      console.log('2. Open your browser console');
      console.log('3. Run the following command in the console:');
      console.log(`   localStorage.setItem('youtube-results', JSON.stringify([${JSON.stringify(nicheScoutResult)}]))`);
      console.log('4. Click the "Load Results" button');
      
    } catch (e) {
      console.error('Error processing results:', e);
    }
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