/**
 * Direct YouTube API Test
 * This script tests direct interaction with the YouTube Data API
 * Without relying on the Social Intelligence Agent
 */

const https = require('https');
const fs = require('fs');

// This would typically be stored in a .env file
// For testing, we'll use a placeholder that should be replaced with a real API key
let API_KEY = 'YOUR_YOUTUBE_API_KEY';

// Try to read API key from a local file (not checked into git)
try {
  if (fs.existsSync('./youtube-api-key.txt')) {
    API_KEY = fs.readFileSync('./youtube-api-key.txt', 'utf8').trim();
    console.log('Using API key from youtube-api-key.txt');
  }
} catch (error) {
  console.warn('Could not read API key file:', error.message);
}

// Function to fetch trending videos
const fetchTrendingVideos = () => {
  return new Promise((resolve, reject) => {
    // API endpoint for trending videos
    const url = `https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&chart=mostPopular&regionCode=US&maxResults=10&key=${API_KEY}`;
    
    console.log(`Fetching trending videos from YouTube API...`);
    
    https.get(url, (res) => {
      if (res.statusCode !== 200) {
        reject(new Error(`API returned status code ${res.statusCode}`));
        return;
      }
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          resolve(response);
        } catch (error) {
          reject(new Error(`Error parsing API response: ${error.message}`));
        }
      });
    }).on('error', (error) => {
      reject(new Error(`HTTP request failed: ${error.message}`));
    });
  });
};

// Function to search for videos by keyword
const searchVideos = (query) => {
  return new Promise((resolve, reject) => {
    // Encode the query for URL
    const encodedQuery = encodeURIComponent(query);
    
    // API endpoint for search
    const url = `https://www.googleapis.com/youtube/v3/search?part=snippet&q=${encodedQuery}&type=video&maxResults=5&key=${API_KEY}`;
    
    console.log(`Searching YouTube for: "${query}"...`);
    
    https.get(url, (res) => {
      if (res.statusCode !== 200) {
        reject(new Error(`API returned status code ${res.statusCode}`));
        return;
      }
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          resolve(response);
        } catch (error) {
          reject(new Error(`Error parsing API response: ${error.message}`));
        }
      });
    }).on('error', (error) => {
      reject(new Error(`HTTP request failed: ${error.message}`));
    });
  });
};

// Function to get channel details
const getChannelDetails = (channelId) => {
  return new Promise((resolve, reject) => {
    // API endpoint for channel details
    const url = `https://www.googleapis.com/youtube/v3/channels?part=snippet,statistics&id=${channelId}&key=${API_KEY}`;
    
    console.log(`Fetching channel details for ID: ${channelId}...`);
    
    https.get(url, (res) => {
      if (res.statusCode !== 200) {
        reject(new Error(`API returned status code ${res.statusCode}`));
        return;
      }
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          resolve(response);
        } catch (error) {
          reject(new Error(`Error parsing API response: ${error.message}`));
        }
      });
    }).on('error', (error) => {
      reject(new Error(`HTTP request failed: ${error.message}`));
    });
  });
};

// Function to analyze a niche based on keywords
const analyzeNiche = async (keywords) => {
  try {
    console.log(`Starting niche analysis for keywords: ${keywords.join(', ')}`);
    
    const results = [];
    
    // Search for each keyword
    for (const keyword of keywords) {
      const searchResult = await searchVideos(keyword);
      
      if (!searchResult.items || searchResult.items.length === 0) {
        console.log(`No results found for keyword: ${keyword}`);
        continue;
      }
      
      let totalViews = 0;
      let totalLikes = 0;
      let videoCount = 0;
      
      // Get video statistics and accumulate totals
      const channelIds = new Set();
      
      for (const item of searchResult.items) {
        const videoId = item.id.videoId;
        const channelId = item.snippet.channelId;
        channelIds.add(channelId);
        
        // Get video details to access statistics (would need separate API call)
        // For simplicity, we're not making that additional call for each video
        
        videoCount++;
      }
      
      // Get channel details for the first channel
      let channelDetails = null;
      if (channelIds.size > 0) {
        const firstChannelId = Array.from(channelIds)[0];
        const channelResult = await getChannelDetails(firstChannelId);
        
        if (channelResult.items && channelResult.items.length > 0) {
          channelDetails = channelResult.items[0];
        }
      }
      
      results.push({
        keyword,
        videoCount,
        channelCount: channelIds.size,
        topChannel: channelDetails ? {
          id: channelDetails.id,
          title: channelDetails.snippet.title,
          subscriberCount: channelDetails.statistics.subscriberCount,
          videoCount: channelDetails.statistics.videoCount,
          viewCount: channelDetails.statistics.viewCount
        } : null
      });
    }
    
    return {
      searchDate: new Date().toISOString(),
      nicheAnalysis: results,
      summary: `Analysis completed for ${keywords.length} keywords: ${keywords.join(', ')}`
    };
  } catch (error) {
    console.error('Error during niche analysis:', error);
    throw error;
  }
};

// Main function to run tests
const runTests = async () => {
  try {
    // Check if we have a real API key
    if (API_KEY === 'YOUR_YOUTUBE_API_KEY') {
      console.error('ERROR: You need to provide a valid YouTube API key.');
      console.log('You can create one at: https://console.developers.google.com/');
      console.log('Then place it in a file named youtube-api-key.txt in the root directory');
      return;
    }
    
    // 1. Test trending videos
    console.log('\n===== TEST 1: TRENDING VIDEOS =====');
    const trendingVideos = await fetchTrendingVideos();
    console.log(`Found ${trendingVideos.items?.length || 0} trending videos`);
    
    if (trendingVideos.items && trendingVideos.items.length > 0) {
      console.log('\nTop trending videos:');
      trendingVideos.items.slice(0, 3).forEach((video, i) => {
        console.log(`${i+1}. "${video.snippet.title}" by ${video.snippet.channelTitle}`);
        console.log(`   Views: ${video.statistics.viewCount}, Likes: ${video.statistics.likeCount}`);
      });
    }
    
    // 2. Test search
    console.log('\n===== TEST 2: SEARCH VIDEOS =====');
    const searchQuery = 'Financial Literacy';
    const searchResults = await searchVideos(searchQuery);
    console.log(`Found ${searchResults.items?.length || 0} videos for "${searchQuery}"`);
    
    if (searchResults.items && searchResults.items.length > 0) {
      console.log('\nTop search results:');
      searchResults.items.slice(0, 3).forEach((video, i) => {
        console.log(`${i+1}. "${video.snippet.title}" by ${video.snippet.channelTitle}`);
        console.log(`   Published: ${video.snippet.publishedAt}`);
      });
    }
    
    // 3. Test niche analysis
    console.log('\n===== TEST 3: NICHE ANALYSIS =====');
    const nicheKeywords = ['Financial Literacy', 'Tech Review Shorts', 'DIY Home Improvement'];
    const nicheAnalysis = await analyzeNiche(nicheKeywords);
    
    console.log('\nNiche Analysis Results:');
    nicheAnalysis.nicheAnalysis.forEach((niche) => {
      console.log(`\nKeyword: ${niche.keyword}`);
      console.log(`Videos Found: ${niche.videoCount}`);
      console.log(`Unique Channels: ${niche.channelCount}`);
      
      if (niche.topChannel) {
        console.log(`Top Channel: ${niche.topChannel.title}`);
        console.log(`Subscribers: ${niche.topChannel.subscriberCount}`);
        console.log(`Channel Views: ${niche.topChannel.viewCount}`);
      }
    });
    
    // Save results to a file
    const outputFile = './youtube-api-test-results.json';
    fs.writeFileSync(outputFile, JSON.stringify({
      timestamp: new Date().toISOString(),
      trending: trendingVideos,
      search: searchResults,
      nicheAnalysis: nicheAnalysis
    }, null, 2));
    
    console.log(`\nAll tests completed. Results saved to ${outputFile}`);
    
  } catch (error) {
    console.error('Error during tests:', error);
  }
};

// Run the tests
runTests();
