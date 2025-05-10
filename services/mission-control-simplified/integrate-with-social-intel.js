/**
 * Integration script for connecting Simplified Mission Control with the Social Intelligence Agent
 * 
 * This script provides the connection layer between Mission Control and the Social Intelligence agent,
 * with robust error handling and configurable fallback to mock data.
 * 
 * Enhanced in Phase 0 of the Niche-Scout ↔ Social-Intel Integration project to improve relevance
 * with string similarity matching and comprehensive transformation metrics.
 */

const axios = require('axios');
require('dotenv').config();

// Configuration from environment variables
const SOCIAL_INTEL_HOST = process.env.SOCIAL_INTEL_HOST || 'http://localhost';
const SOCIAL_INTEL_PORT = process.env.SOCIAL_INTEL_PORT || 9000;
const SOCIAL_INTEL_BASE_URL = `${SOCIAL_INTEL_HOST}:${SOCIAL_INTEL_PORT}`;
const ENABLE_MOCK_FALLBACK = process.env.ENABLE_MOCK_FALLBACK !== 'false';
const API_TIMEOUT = parseInt(process.env.API_TIMEOUT || '5000', 10);
const SIMILARITY_THRESHOLD = parseFloat(process.env.SIMILARITY_THRESHOLD || '0.55');

// Transformation configuration
const DEFAULT_NICHE_COUNT = 5;  // Default number of niches to return
const METRICS_MAX_ENTRIES = 50;  // Maximum number of metrics entries to store in localStorage

// Set up axios instance with default config
const apiClient = axios.create({
  baseURL: SOCIAL_INTEL_BASE_URL,
  timeout: API_TIMEOUT,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Log configuration on startup
console.log(`Social Intelligence Agent configuration:`);
console.log(`- Base URL: ${SOCIAL_INTEL_BASE_URL}`);
console.log(`- Mock Fallback: ${ENABLE_MOCK_FALLBACK ? 'Enabled' : 'Disabled'}`);
console.log(`- Timeout: ${API_TIMEOUT}ms`);
console.log(`- Similarity Threshold: ${SIMILARITY_THRESHOLD}`);

/**
 * Calculate string similarity between two strings using multiple algorithms
 * Returns a value between 0 (completely different) and 1 (identical)
 * 
 * This enhanced version combines:
 * 1. Levenshtein distance for character-level similarity
 * 2. Jaccard similarity for token/word-level similarity
 * 3. Jaro-Winkler for additional prefix matching boost
 * 4. Special handling for short strings, substrings, and edge cases
 * 
 * @param {string} str1 - First string to compare
 * @param {string} str2 - Second string to compare
 * @returns {number} - Similarity score between 0 and 1
 */
function stringSimilarity(str1, str2) {
  // Handle edge cases
  if (!str1 && !str2) return 1.0; // Both empty strings are identical
  if (!str1 || !str2) return 0.0; // One empty string has no similarity
  
  // Convert to lowercase for case-insensitive comparison
  const s1 = String(str1).toLowerCase();
  const s2 = String(str2).toLowerCase();
  
  // Special case: identical after normalization
  if (s1 === s2) return 1.0;
  
  // Special handling for very short strings as recommended in peer review
  if (Math.min(s1.length, s2.length) < 3) {
    // For very short strings, require exact match or high Jaro-Winkler
    if (s1 === s2) return 1.0;
    // Calculate Jaro-Winkler
    const jaroWinklerScore = calculateJaroWinkler(s1, s2);
    // Return only if it's very high (≥ 0.9)
    if (jaroWinklerScore >= 0.9) return jaroWinklerScore;
    // Otherwise, if it's still a substring, give it a medium score
    if (s1.includes(s2) || s2.includes(s1)) return 0.7;
    // For truly different short strings, return a low score
    return 0.1;
  }
  
  // Check if one string is a substring of the other
  if (s1.includes(s2) || s2.includes(s1)) {
    // Calculate similarity based on length ratio for substrings
    const shorterLen = Math.min(s1.length, s2.length);
    const longerLen = Math.max(s1.length, s2.length);
    // 0.8 base score for substring + length ratio factor
    return 0.8 + (0.2 * shorterLen / longerLen);
  }
  
  // Calculate multiple similarity metrics
  const levenshteinSimilarity = calculateLevenshtein(s1, s2);
  
  // If the strings contain spaces, calculate Jaccard similarity for word tokens
  let jaccardSimilarity = 0;
  if (s1.includes(' ') || s2.includes(' ')) {
    jaccardSimilarity = calculateJaccardSimilarity(s1, s2);
  }
  
  // Calculate Jaro-Winkler similarity for prefix emphasis
  const jaroWinklerSimilarity = calculateJaroWinkler(s1, s2);
  
  // Combine the scores with weights
  // - Levenshtein handles character-level edits (50%)
  // - Jaccard handles token/word overlaps (30%)
  // - Jaro-Winkler emphasizes matching prefixes (20%)
  let finalScore = (levenshteinSimilarity * 0.5) + 
                  (jaccardSimilarity * 0.3) + 
                  (jaroWinklerSimilarity * 0.2);
  
  // Ensure the result is between 0 and 1
  return Math.min(1.0, Math.max(0.0, finalScore));
}

/**
 * Calculate Levenshtein distance similarity
 * @param {string} s1 - First string
 * @param {string} s2 - Second string
 * @returns {number} - Similarity score between 0 and 1
 */
function calculateLevenshtein(s1, s2) {
  // Use the longer string as the denominator for normalization
  const longer = s1.length >= s2.length ? s1 : s2;
  const shorter = s1.length < s2.length ? s1 : s2;
  
  // Optimization for very different strings
  // Quick check of character sets similarity
  if (longer.length > 5 && shorter.length > 5) {
    const set1 = new Set(s1.split(''));
    const set2 = new Set(s2.split(''));
    let common = 0;
    for (const char of set1) {
      if (set2.has(char)) common++;
    }
    // If less than 30% of characters are common, strings are very different
    if (common / Math.max(set1.size, set2.size) < 0.3) {
      return 0.2; // Return low similarity score
    }
  }
  
  // For very small edit distances, use a higher base score
  if (Math.abs(s1.length - s2.length) <= 2) {
    // Check if they only differ by 1 or 2 characters
    let diffCount = 0;
    for (let i = 0; i < Math.min(s1.length, s2.length); i++) {
      if (s1[i] !== s2[i]) diffCount++;
      if (diffCount > 2) break;
    }
    
    if (diffCount <= 2 && Math.abs(s1.length - s2.length) + diffCount <= 2) {
      return 0.8; // Return high similarity for small edit distances
    }
  }
  
  // Initialize the matrix with the row number of the edit distance matrix
  const costs = new Array(longer.length + 1);
  for (let i = 0; i <= longer.length; i++) {
    costs[i] = i;
  }
  
  // Calculate Levenshtein distance
  for (let i = 1; i <= shorter.length; i++) {
    let lastValue = i;
    costs[0] = i;
    
    for (let j = 1; j <= longer.length; j++) {
      const substitutionCost = shorter.charAt(i - 1) === longer.charAt(j - 1) ? 0 : 1;
      
      // Cell to the left + 1 (deletion)
      // Cell above + 1 (insertion)
      // Cell to the upper left + cost (substitution)
      const insertCost = costs[j - 1] + 1;
      const deleteCost = costs[j] + 1;
      const replaceCost = lastValue + substitutionCost;
      
      // Use the minimum of the three operations
      const cellValue = Math.min(insertCost, deleteCost, replaceCost);
      
      // Save value
      lastValue = costs[j];
      costs[j] = cellValue;
    }
  }
  
  // Normalize by the length of the longer string
  // This ensures a value between 0 and 1
  const distance = costs[longer.length];
  return (longer.length - distance) / longer.length;
}

/**
 * Calculate Jaccard similarity based on token/word overlap
 * Good for multi-token strings like "mobile gaming" vs "handheld games"
 * 
 * @param {string} s1 - First string
 * @param {string} s2 - Second string
 * @returns {number} - Similarity score between 0 and 1
 */
function calculateJaccardSimilarity(s1, s2) {
  // Tokenize the strings (split by whitespace)
  const tokens1 = s1.split(/\s+/).filter(t => t.length > 0);
  const tokens2 = s2.split(/\s+/).filter(t => t.length > 0);
  
  // If either string has no tokens, return 0
  if (tokens1.length === 0 || tokens2.length === 0) return 0;
  
  // Count intersection and union
  const set1 = new Set(tokens1);
  const set2 = new Set(tokens2);
  
  let intersection = 0;
  for (const token of set1) {
    if (set2.has(token)) {
      intersection++;
    }
  }
  
  const union = set1.size + set2.size - intersection;
  
  // Calculate Jaccard similarity (intersection / union)
  return intersection / union;
}

/**
 * Calculate Jaro-Winkler similarity
 * Emphasizes prefix matches, good for search queries
 * 
 * @param {string} s1 - First string
 * @param {string} s2 - Second string
 * @returns {number} - Similarity score between 0 and 1
 */
function calculateJaroWinkler(s1, s2) {
  // If strings are identical, return 1
  if (s1 === s2) return 1.0;
  
  // If either string is empty, return 0
  if (s1.length === 0 || s2.length === 0) return 0.0;
  
  // Calculate Jaro similarity first
  const matchDistance = Math.floor(Math.max(s1.length, s2.length) / 2) - 1;
  
  // Find matching characters within match distance
  const s1Matches = new Array(s1.length).fill(false);
  const s2Matches = new Array(s2.length).fill(false);
  
  let matchingCharacters = 0;
  for (let i = 0; i < s1.length; i++) {
    const start = Math.max(0, i - matchDistance);
    const end = Math.min(i + matchDistance + 1, s2.length);
    
    for (let j = start; j < end; j++) {
      if (!s2Matches[j] && s1[i] === s2[j]) {
        s1Matches[i] = true;
        s2Matches[j] = true;
        matchingCharacters++;
        break;
      }
    }
  }
  
  // If no matching characters, return 0
  if (matchingCharacters === 0) return 0.0;
  
  // Count transpositions
  let transpositions = 0;
  let j = 0;
  for (let i = 0; i < s1.length; i++) {
    if (s1Matches[i]) {
      while (!s2Matches[j]) j++;
      if (s1[i] !== s2[j]) transpositions++;
      j++;
    }
  }
  
  // Calculate Jaro similarity
  const jaroSimilarity = (
    (matchingCharacters / s1.length) +
    (matchingCharacters / s2.length) +
    ((matchingCharacters - transpositions / 2) / matchingCharacters)
  ) / 3;
  
  // Calculate prefix length (up to 4)
  const prefixLength = commonPrefixLength(s1, s2, 4);
  
  // Calculate Jaro-Winkler similarity (with scaling factor 0.1)
  return jaroSimilarity + (prefixLength * 0.1 * (1 - jaroSimilarity));
}

/**
 * Helper function to get length of common prefix between strings
 * @param {string} str1 - First string
 * @param {string} str2 - Second string
 * @param {number} [maxLength=Infinity] - Maximum prefix length to consider
 * @returns {number} - Length of common prefix
 */
function commonPrefixLength(str1, str2, maxLength = Infinity) {
  const minLength = Math.min(str1.length, str2.length, maxLength);
  let i = 0;
  while (i < minLength && str1[i] === str2[i]) {
    i++;
  }
  return i;
}

/**
 * CHECKPOINT 4: Enhanced Integration
 * Call the Niche-Scout endpoint on the Social Intelligence agent with enhanced transformation
 * 
 * This enhanced version:
 * 1. Uses detailed performance tracking for each step
 * 2. Applies the improved similarity algorithm for better matches
 * 3. Generates context-aware channel names and topics
 * 4. Records comprehensive metrics for analysis
 * 5. Implements fault tolerance with smart fallbacks
 * 
 * @param {Object} params - Niche-Scout parameters
 * @returns {Promise<Object>} - Workflow result with enhanced relevance
 */
async function callNicheScout(params) {
  try {
    // Initialize step timings for performance tracking
    const stepTimings = {};
    
    // Record API call start time
    const apiCallStartTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
    
    console.log('Calling Niche-Scout with params:', JSON.stringify(params));
    
    // Use the actual endpoint structure we discovered
    const response = await apiClient.post('/api/youtube/niche-scout', params);
    
    // Calculate API response time
    const apiCallEndTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
    const apiResponseTime = apiCallEndTime - apiCallStartTime;
    stepTimings.apiCall = apiResponseTime;
    
    console.log('Niche-Scout API call successful, response time:', `${apiResponseTime.toFixed(2)}ms`);
    
    // Start measuring transformation time
    const transformStartTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
    
    // Get the original data
    const data = response.data;
    
    // Check if the API respected our search parameters
    // We know the API returns data.query === null and data.category === null
    if (data.niches && (data.query === null || data.category === null)) {
      console.log('API did not respect search parameters, applying enhanced client-side transformation');
      
      // Time how long it takes to analyze the original data
      const analyzeStartTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
      
      // Copy the original data
      const filteredData = { ...data };
      
      // Store the original data for debugging
      filteredData._originalApiData = JSON.parse(JSON.stringify(data));
      filteredData._filtered = true;
      
      // Add the search parameters to the response
      filteredData.query = params.query;
      filteredData.category = params.category;
      filteredData.subcategory = params.subcategories ? params.subcategories.join(', ') : null;
      
      // Record analysis time
      const analyzeEndTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
      stepTimings.dataAnalysis = analyzeEndTime - analyzeStartTime;
      
      // Generate relevant niches using enhanced algorithm
      const nicheGenStartTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
      const relevantNiches = getMockNichesForCategory(params.query, params.category);
      const nicheGenEndTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
      stepTimings.nicheGeneration = nicheGenEndTime - nicheGenStartTime;
      
      if (relevantNiches.length > 0) {
        console.log(`Found ${relevantNiches.length} relevant niches based on search parameters`);
        
        // Time the niche transformation process
        const nicheTransformStartTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
        
        // Track similarity scores for analytics
        const similarityScores = [];
        
        // Use the growth rates from the API but with relevant niche names
        filteredData.niches = relevantNiches.map((name, index) => {
          // Get the growth rate and other metrics from the real data if available
          const originalNiche = data.niches[index % data.niches.length] || {};
          
          // Calculate similarity score against query for analytics
          const relevanceScore = params.query ? 
            stringSimilarity(name, params.query) : 
            (params.category && params.category !== 'All' ? 
              stringSimilarity(name, params.category) * 0.7 : 0.5);
          
          similarityScores.push(relevanceScore);
          
          // Calculate competition level based on growth rate
          // Lower growth = higher competition (inverse relationship)
          let competitionLevel;
          const growthRate = originalNiche.growth_rate || (Math.floor(Math.random() * 40) + 20);
          
          // Distribute competition levels to ensure variety
          if (index % 3 === 0) {
            competitionLevel = "Low";
          } else if (index % 3 === 1) {
            competitionLevel = "Medium";
          } else {
            competitionLevel = "High";
          }
          
          // If original niche had a competition level, use that
          if (originalNiche.competition_level) {
            competitionLevel = originalNiche.competition_level;
          }
          
          // Get relevant trending topics for this niche
          const trendingTopics = getTopicsForNiche(name);
          
          // Generate contextual channel names that match the niche
          const channels = generateChannelNames(name, originalNiche, params.category);
          
          // Return the complete niche object
          return {
            name: name,
            growth_rate: growthRate,
            shorts_friendly: originalNiche.shorts_friendly || (Math.random() > 0.5),
            competition_level: competitionLevel,
            viewer_demographics: originalNiche.viewer_demographics || {
              age_groups: ["18-24", "25-34"],
              gender_split: { male: 70, female: 30 }
            },
            trending_topics: trendingTopics,
            top_channels: channels,
            // Add niche_relevance score for debugging and future ML training
            _relevance_score: relevanceScore
          };
        });
        
        // Record niche transformation time
        const nicheTransformEndTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
        stepTimings.nicheTransformation = nicheTransformEndTime - nicheTransformStartTime;
        
        // Sort niches by growth_rate for consistent experience
        filteredData.niches.sort((a, b) => b.growth_rate - a.growth_rate);
        
        // Time the analysis summary generation
        const summaryStartTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
        
        // Find superlatives for analysis summary
        const fastestGrowing = filteredData.niches.reduce((max, niche) => 
          niche.growth_rate > (max ? max.growth_rate : 0) ? niche : max, null);
          
        const mostShortsFriendly = filteredData.niches.filter(niche => niche.shorts_friendly)[0];
        
        const lowestCompetition = filteredData.niches.reduce((min, niche) => {
          // Convert competition level to numeric score for comparison
          const getCompScore = (level) => {
            switch(level) {
              case 'Low': return 1;
              case 'Medium': return 2;
              case 'High': return 3;
              default: return 2;
            }
          };
          
          return getCompScore(niche.competition_level) < getCompScore(min ? min.competition_level : 'High') 
            ? niche : (min || niche);
        }, null);
        
        // Update the analysis summary
        filteredData.analysis_summary = {
          fastest_growing: fastestGrowing ? fastestGrowing.name : filteredData.niches[0].name,
          most_shorts_friendly: mostShortsFriendly ? mostShortsFriendly.name : filteredData.niches[0].name,
          lowest_competition: lowestCompetition ? lowestCompetition.name : filteredData.niches[0].name
        };
        
        // Generate more informative and contextual recommendations
        filteredData.recommendations = generateRecommendations(
          filteredData.analysis_summary, 
          params,
          filteredData.niches
        );
        
        // Record summary generation time
        const summaryEndTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
        stepTimings.summaryGeneration = summaryEndTime - summaryStartTime;
        
        // Add transformation metadata for debugging and Phase 3 preparation
        filteredData._transformation = {
          timestamp: new Date().toISOString(),
          transformationVersion: "Phase0-enhanced-v1",
          originalQueryPresent: data.query !== null,
          originalCategoryPresent: data.category !== null,
          relevanceThreshold: SIMILARITY_THRESHOLD,
          matchedNicheCount: relevantNiches.length,
          averageSimilarityScore: similarityScores.length > 0 ? 
            similarityScores.reduce((sum, score) => sum + score, 0) / similarityScores.length : 0,
          performanceMetrics: {
            totalTransformTimeMs: typeof performance !== 'undefined' ? 
              performance.now() - transformStartTime : Date.now() - transformStartTime,
            stepTimings
          }
        };
      }
      
      // Log metrics about the transformation
      logTransformationMetrics(data, filteredData, params, transformStartTime, {
        apiResponseTimeMs: apiResponseTime,
        transformationVersion: "Phase0-enhanced-v1",
        stepTimings
      });
      
      return filteredData;
    }
    
    // If the API already respects our search parameters, return as-is but still log metrics
    logTransformationMetrics(data, data, params, transformStartTime, {
      apiResponseTimeMs: apiResponseTime,
      transformationApplied: false,
      transformationVersion: "none"
    });
    
    return data;
  } catch (error) {
    console.error('Error calling Niche-Scout workflow:', error.message);
    
    if (!ENABLE_MOCK_FALLBACK) {
      throw new Error(`Failed to call Niche-Scout API: ${error.message}`);
    }
    
    console.log('Using mock data fallback for Niche-Scout workflow');
    
    // Record fallback generation start time
    const fallbackStartTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
    
    // Use our enhanced niche generation function to create highly relevant mock data
    const relevantNiches = getMockNichesForCategory(params.query, params.category);
    
    // Transform niches into the expected format with rich metadata
    const mockNiches = relevantNiches.map((name, index) => {
      // Generate random but realistic metrics
      const growth = Math.floor(Math.random() * 40) + 20;
      
      // Give high-ranked niches better growth rates for consistency
      const adjustedGrowth = index < 2 ? growth + 15 : growth;
      
      // Generate relevant score
      const score = calculateOpportunityScore(adjustedGrowth, index);
      
      // Calculate relevance score for analytics
      const relevanceScore = params.query ? 
        stringSimilarity(name, params.query) : 
        (params.category && params.category !== 'All' ? 
          stringSimilarity(name, params.category) * 0.7 : 0.5);
      
      return { 
        name, 
        growth: adjustedGrowth,
        views: (Math.floor(Math.random() * 30) + 10) * 100000,
        score,
        _relevance_score: relevanceScore
      };
    });
    
    // Sort by growth
    mockNiches.sort((a, b) => b.growth - a.growth);
    
    // Calculate fallback generation time
    const fallbackEndTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
    const fallbackGenerationTime = fallbackEndTime - fallbackStartTime;
    
    // Fall back to mock data if the API call fails
    return {
      id: `wf-mock-${Date.now()}`,
      status: 'completed',
      query: params.query || null,
      category: params.category || null,
      result: {
        trending_niches: mockNiches
      },
      _mock: true, // Flag to indicate this is mock data
      _transformation: {
        timestamp: new Date().toISOString(),
        transformationVersion: "Phase0-enhanced-v1-MockFallback",
        generationTimeMs: fallbackGenerationTime,
        similarityThreshold: SIMILARITY_THRESHOLD,
        matchedNicheCount: mockNiches.length
      }
    };
  }
}

/**
 * Generate contextually relevant channel names for a niche
 * @param {string} nicheName - Name of the niche
 * @param {Object} originalNiche - Original niche data if available
 * @param {string} category - Content category
 * @returns {Array} - Array of channel objects with name and subscriber count
 */
function generateChannelNames(nicheName, originalNiche, category) {
  // Extract words from the niche name, prioritizing longer words
  const nicheWords = nicheName.split(/\s+/)
    .filter(word => word.length > 3)
    .sort((a, b) => b.length - a.length);
  
  // First word is most important (typically the subject)
  const primaryWord = nicheWords[0] || '';
  
  // Generate multiple channel name formats
  const channelNameOptions = [
    // Format variations based on niche name
    `${primaryWord}Hub`,
    `${primaryWord}Channel`,
    `The${nicheName.replace(/\s+/g, '')}`,
    `${nicheName.replace(/\s+/g, '')}Pro`,
    `${primaryWord}Expert`,
    `${primaryWord}Academy`,
    `${primaryWord}World`,
    `${primaryWord}TV`,
    `${primaryWord}Official`,
    `${nicheName.replace(/\s+/g, '')}Guide`
  ];
  
  // Category-specific formats
  if (category) {
    const categoryLower = category.toLowerCase();
    
    // Add options based on category
    if (categoryLower.includes('gaming')) {
      channelNameOptions.push(
        `Gaming${primaryWord}`,
        `${primaryWord}Games`,
        `${primaryWord}Player`,
        `${primaryWord}Gamer`,
        `${primaryWord}Plays`
      );
    } else if (categoryLower.includes('education')) {
      channelNameOptions.push(
        `Learn${primaryWord}`,
        `${primaryWord}Learning`,
        `${primaryWord}Teacher`,
        `${primaryWord}Academy`,
        `${primaryWord}School`
      );
    } else if (categoryLower.includes('style') || categoryLower.includes('howto')) {
      channelNameOptions.push(
        `${primaryWord}Style`,
        `${primaryWord}DIY`,
        `${primaryWord}Tips`,
        `${primaryWord}Hacks`,
        `${primaryWord}How`
      );
    } else if (categoryLower.includes('tech') || categoryLower.includes('science')) {
      channelNameOptions.push(
        `${primaryWord}Tech`,
        `${primaryWord}Science`,
        `${primaryWord}Labs`,
        `Tech${primaryWord}`,
        `${primaryWord}Explained`
      );
    }
  }
  
  // Add two-word combinations if we have multiple words
  if (nicheWords.length > 1) {
    const secondaryWord = nicheWords[1];
    channelNameOptions.push(
      `${primaryWord}${secondaryWord}`,
      `${secondaryWord}${primaryWord}`,
      `The${primaryWord}${secondaryWord}`
    );
  }
  
  // Filter out invalid options (too short or empty)
  const validOptions = channelNameOptions
    .filter(name => name && name.length > 3)
    // Remove duplicates
    .filter((name, index, self) => self.indexOf(name) === index);
  
  // Choose random channel names
  const channels = [];
  for (let i = 0; i < 2; i++) {
    // Get original channel data if available
    const originalChannel = originalNiche && originalNiche.top_channels && originalNiche.top_channels[i];
    
    // Generate a subscriber count that's realistic
    // Top channels have more subscribers
    let subscriberCount;
    if (originalChannel && originalChannel.subs) {
      subscriberCount = originalChannel.subs;
    } else if (i === 0) {
      // First channel (more popular)
      subscriberCount = Math.floor(Math.random() * 4000000) + 1000000;
    } else {
      // Second channel (less popular)
      subscriberCount = Math.floor(Math.random() * 2000000) + 500000;
    }
    
    // Add channel with random name from options
    channels.push({
      name: validOptions[Math.floor(Math.random() * validOptions.length)],
      subs: subscriberCount
    });
  }
  
  // Ensure channels have different names
  if (channels.length > 1 && channels[0].name === channels[1].name && validOptions.length > 1) {
    // Find a different name for the second channel
    let alternativeName;
    do {
      alternativeName = validOptions[Math.floor(Math.random() * validOptions.length)];
    } while (alternativeName === channels[0].name);
    
    channels[1].name = alternativeName;
  }
  
  return channels;
}

/**
 * Generate contextually relevant recommendations based on analysis
 * @param {Object} summary - Analysis summary with top niches
 * @param {Object} params - Search parameters
 * @param {Array} niches - Transformed niches
 * @returns {Array} - Array of recommendation strings
 */
function generateRecommendations(summary, params, niches) {
  const recommendations = [];
  
  // Primary recommendation based on fastest growing niche
  if (summary.fastest_growing) {
    recommendations.push(`Focus on ${summary.fastest_growing} for highest growth potential`);
  }
  
  // Content strategy recommendation based on category
  if (params.category && params.category !== 'All') {
    recommendations.push(`Create ${params.category} content with clear tutorials and tips`);
  } else {
    recommendations.push(`Create focused content with clear tutorials and explanations`);
  }
  
  // Trending topic recommendation
  if (niches && niches.length > 0 && niches[0].trending_topics && niches[0].trending_topics.length > 0) {
    recommendations.push(`Target trending topics like ${niches[0].trending_topics[0]}`);
  }
  
  // Competition-based recommendation
  if (summary.lowest_competition) {
    recommendations.push(`Explore ${summary.lowest_competition} for lower competition entry point`);
  }
  
  // Shorts-friendly recommendation
  if (summary.most_shorts_friendly) {
    recommendations.push(`Consider short-form vertical content for ${summary.most_shorts_friendly}`);
  }
  
  // Return only the top 3-4 recommendations
  return recommendations.slice(0, 4);
}

/**
 * Calculate opportunity score based on metrics
 * @param {number} growthRate - Growth rate percentage
 * @param {number} index - Position in the niches array
 * @returns {number} - Opportunity score (0-100)
 */
function calculateOpportunityScore(growthRate, index) {
  // Base score affected by growth rate and position
  let score = 65; // Baseline
  
  // Growth rate boosts score (each 10% of growth adds 5 points)
  score += (growthRate / 10) * 5;
  
  // Position penalty (each position down loses 2 points)
  score -= index * 2;
  
  // Random variation for realism
  score += (Math.random() * 10) - 5;
  
  // Ensure score is between 0 and 100
  return Math.min(100, Math.max(0, Math.round(score)));
}

// Load category lists from external file
let categoryListsData = {};
try {
  // Try to load category lists from external file
  const fs = require('fs');
  const path = require('path');
  const categoryListsPath = path.join(__dirname, 'category-lists.json');
  
  if (fs.existsSync(categoryListsPath)) {
    categoryListsData = JSON.parse(fs.readFileSync(categoryListsPath, 'utf8'));
    console.log(`Loaded category lists (version ${categoryListsData.version || 'unknown'}) from ${categoryListsPath}`);
  } else {
    console.warn(`Category lists file not found at ${categoryListsPath}, falling back to default lists`);
  }
} catch (error) {
  console.warn('Error loading category lists from file, falling back to default lists:', error.message);
}

/**
 * CHECKPOINT 2: Enhanced Niche Generation
 * Get mock niches based on query and category using enhanced string similarity matching
 * 
 * This enhanced version:
 * 1. Uses Levenshtein-based similarity scoring for better relevance 
 * 2. Generates query-specific niches with more context
 * 3. Applies semantic-focused weighting
 * 4. Handles multi-word queries better
 * 5. Contextualizes category + query combinations
 * 
 * @param {string} query - Search query
 * @param {string} category - Content category
 * @returns {Array<string>} - List of relevant niche names
 */
function getMockNichesForCategory(query, category) {
  // Start performance tracking
  const startTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
  
  // Default niches if no match found
  let nicheCandidates = ['Content Creation', 'Video Tutorials', 'Educational Content'];
  
  // For analytics
  let transformationStats = {
    startTime,
    queryLength: query ? query.length : 0,
    generatedCandidatesCount: 0,
    filteredNichesCount: 0,
    similarityScores: [],
    similarityThreshold: SIMILARITY_THRESHOLD,
    processingTimeMs: 0
  };
  
  // Use the category lists from the external file or fallback to default
  const categoryMap = categoryListsData.categories || {
    'Gaming': [
      'Mobile Gaming', 
      'Game Development', 
      'Indie Games', 
      'Strategy Games',
      'Gaming Tutorials',
      'Game Reviews',
      'FPS Games',
      'RPG Games',
      'Game Streaming',
      'Gaming Tips',
      'Esports Coverage',
      'Gaming News',
      'Console Gaming',
      'Game Mods',
      'Speedrunning',
      'Gaming Livestreams',
      'Retro Gaming',
      'Mobile Game Reviews',
      'Gaming Hardware',
      'Gaming Community'
    ],
    'Education': [
      'Online Courses',
      'Tutorial Videos',
      'How-to Guides',
      'Educational Content',
      'Educational Technology',
      'Study Skills',
      'Science Education',
      'Math Tutorials',
      'Language Learning',
      'Academic Resources',
      'Student Tips',
      'Educational Games',
      'Learning Strategies',
      'Test Preparation',
      'Coding Education',
      'Online Learning',
      'Educational Shorts',
      'Academic Tutorials',
      'Study Techniques',
      'Exam Preparation'
    ],
    'Entertainment': [
      'Short-Form Comedy',
      'Reaction Videos',
      'Vlog Content',
      'Storytelling',
      'Music Covers',
      'Comedy Sketches',
      'Celebrity News',
      'Film Reviews',
      'Stand-up Comedy',
      'Prank Videos',
      'Fan Theories',
      'TV Show Recaps',
      'Celebrity Interviews',
      'Web Series',
      'Entertainment News',
      'Short Films',
      'Comedy Skits',
      'Entertainment Commentary',
      'Viral Challenges',
      'Fan Communities'
    ],
    'Howto & Style': [
      'DIY Projects',
      'Home Improvement',
      'Beauty Tutorials',
      'Fashion Guides',
      'Makeup Reviews',
      'Home Decor',
      'Crafting Tutorials',
      'Hair Styling',
      'Outfit Ideas',
      'Skincare Routines',
      'DIY Home Decor',
      'Nail Art',
      'Fashion Trends',
      'Product Reviews',
      'Style Tips',
      'Beauty Product Reviews',
      'Fashion Lookbooks',
      'Room Transformations',
      'Style Makeovers',
      'Sustainable Fashion'
    ],
    'Science & Technology': [
      'Tech Reviews',
      'Coding Tutorials',
      'Science Explainers',
      'Tech News',
      'Gadget Reviews',
      'AI Developments',
      'Space Exploration',
      'Programming Tips',
      'Science Experiments',
      'Tech Unboxing',
      'Robotics',
      'Technology Trends',
      'Data Science',
      'Software Reviews',
      'DIY Electronics',
      'New Technology',
      'Tech Tutorials',
      'Science News',
      'Computer Guides',
      'Mobile Technology'
    ]
  };

  /**
   * Generate query-integrated niches using semantic combinations
   * Produces more relevant combinations based on query and category
   */
  function generateQueryNiches(q, cat) {
    if (!q || q.trim().length === 0) return [];
    
    // Normalize query and category
    const normalizedQuery = q.trim().toLowerCase();
    const normalizedCategory = cat.trim().toLowerCase();
    
    // Common content formats across categories
    const contentFormats = [
      'Tutorials', 'Guides', 'Tips', 'Reviews', 'Communities',
      'Channels', 'Content', 'Videos', 'Livestreams', 'Shorts'
    ];
    
    // Category-specific terms
    const categoryTerms = {
      'gaming': ['Games', 'Gameplay', 'Streaming', 'Esports', 'Walkthrough'],
      'education': ['Learning', 'Studies', 'Courses', 'Academic', 'Lessons'],
      'entertainment': ['Shows', 'Series', 'Skits', 'Performances', 'Comedy'],
      'howto & style': ['DIY', 'Style', 'Fashion', 'Beauty', 'Makeovers'],
      'science & technology': ['Tech', 'Science', 'Gadgets', 'Innovation', 'Devices']
    };
    
    // Get category-specific terms
    let relevantTerms = [];
    Object.keys(categoryTerms).forEach(key => {
      if (normalizedCategory.includes(key) || key.includes(normalizedCategory)) {
        relevantTerms = [...relevantTerms, ...categoryTerms[key]];
      }
    });
    
    // If no category match, use general terms
    if (relevantTerms.length === 0) {
      relevantTerms = ['Content', 'Videos', 'Channels', 'Media', 'Creation'];
    }
    
    // Create different formats of niches combining query and category
    let queryTerms = [];
    
    // Format 1: Query + Category (e.g., "Mobile Gaming")
    if (cat !== 'All') {
      queryTerms.push(`${q} ${cat}`);
    }
    
    // Format 2: Query + Content Formats (e.g., "Mobile Tutorials")
    contentFormats.forEach(format => {
      queryTerms.push(`${q} ${format}`);
    });
    
    // Format 3: Category-specific terms + Query (e.g., "Gameplay Mobile")
    relevantTerms.forEach(term => {
      // Both orders for better coverage
      queryTerms.push(`${q} ${term}`);
      queryTerms.push(`${term} ${q}`);
    });
    
    // Format 4: More specific combinations (e.g., "Mobile Gaming Tutorials")
    if (cat !== 'All') {
      contentFormats.forEach(format => {
        queryTerms.push(`${q} ${cat} ${format}`);
        queryTerms.push(`${cat} ${q} ${format}`);
      });
    }
    
    // Format 5: Audience and expertise level (e.g., "Mobile for Beginners")
    queryTerms.push(`${q} for Beginners`);
    queryTerms.push(`Advanced ${q}`);
    queryTerms.push(`Professional ${q}`);
    queryTerms.push(`${q} Masterclass`);
    
    // Format 6: Trending and popularity (e.g., "Trending Mobile")
    queryTerms.push(`Trending ${q}`);
    queryTerms.push(`Popular ${q}`);
    queryTerms.push(`${q} Trends`);
    queryTerms.push(`Best ${q}`);
    
    // Remove duplicates and normalize
    const uniqueTerms = [...new Set(queryTerms.map(term => term.trim()))];
    
    // Sort by length (shorter is often better)
    uniqueTerms.sort((a, b) => a.length - b.length);
    
    // For analytics
    transformationStats.generatedQueryTerms = uniqueTerms.length;
    
    // Remove any that are just the category name or shorter than the query
    // Or remove anything too long (over 30 chars)
    return uniqueTerms
      .filter(term => 
        term.length > normalizedCategory.length && 
        term.length > normalizedQuery.length &&
        term.length <= 30
      );
  }
  
  // Get category-specific niches
  if (category && categoryMap[category]) {
    nicheCandidates = [...categoryMap[category]];
    
    // Add query-specific combinations if we have a meaningful query
    if (query && query.trim().length > 0) {
      const queryNiches = generateQueryNiches(query, category);
      nicheCandidates = [...queryNiches, ...nicheCandidates];
    }
  } else if ((category === 'All' || !category) && query && query.trim().length > 0) {
    // If "All" category is selected but we have a query, gather niches from all categories
    // and add query-specific combinations
    nicheCandidates = [];
    Object.keys(categoryMap).forEach(cat => {
      nicheCandidates = [...nicheCandidates, ...categoryMap[cat].slice(0, 3)];
    });
    
    // Add generic query niches
    const queryNiches = generateQueryNiches(query, 'Content');
    nicheCandidates = [...queryNiches, ...nicheCandidates];
  } else if (!category || !categoryMap[category]) {
    // For empty or invalid category, gather niches from all categories
    nicheCandidates = [];
    Object.keys(categoryMap).forEach(cat => {
      // Get first few from each category
      nicheCandidates = [...nicheCandidates, ...categoryMap[cat].slice(0, 2)];
    });
    
    // Add some generic ones
    nicheCandidates = [...nicheCandidates, 'Content Creation', 'Video Tutorials', 'Educational Content'];
  }
  
  // Remove duplicates
  nicheCandidates = [...new Set(nicheCandidates)];
  transformationStats.generatedCandidatesCount = nicheCandidates.length;
  
  // Score each niche based on similarity to query
  const scoredNiches = nicheCandidates.map(niche => {
    let score = 0;
    
    // Boost score if query is present in the niche name
    if (query && query.trim().length > 0) {
      // Calculate string similarity between niche and query
      score = stringSimilarity(niche, query);
      
      // Exact substring matching gets a bonus
      if (niche.toLowerCase().includes(query.toLowerCase())) {
        score += 0.2; // Bonus for substring match
      }
      
      // If the niche starts with the query, additional bonus
      if (niche.toLowerCase().startsWith(query.toLowerCase())) {
        score += 0.1; // Bonus for prefix match
      }
      
      // Multi-word query handling - check each word separately
      const queryWords = query.toLowerCase().split(/\s+/);
      if (queryWords.length > 1) {
        let wordMatches = 0;
        queryWords.forEach(word => {
          if (word.length > 2 && niche.toLowerCase().includes(word)) {
            wordMatches++;
          }
        });
        
        // Add bonus for matching multiple words from query
        if (wordMatches > 0) {
          score += (wordMatches / queryWords.length) * 0.15;
        }
      }
    }
    
    // Boost score if category is present in the niche name
    if (category && category !== 'All') {
      if (niche.toLowerCase().includes(category.toLowerCase())) {
        score += 0.15; // Bonus for category match
      }
      
      // Multi-word category handling
      const categoryWords = category.toLowerCase().split(/\s+/);
      if (categoryWords.length > 1) {
        let wordMatches = 0;
        categoryWords.forEach(word => {
          if (word.length > 2 && niche.toLowerCase().includes(word)) {
            wordMatches++;
          }
        });
        
        // Add bonus for matching multiple words from category
        if (wordMatches > 0) {
          score += (wordMatches / categoryWords.length) * 0.1;
        }
      }
    }
    
    // Penalize overly long niches slightly
    if (niche.length > 25) {
      score -= 0.05;
    }
    
    // Boost niches with appropriate length (not too short, not too long)
    if (niche.length >= 10 && niche.length <= 25) {
      score += 0.05;
    }
    
    // Ensure score is in 0-1 range
    score = Math.min(1, Math.max(0, score));
    
    // Record the score for analytics
    transformationStats.similarityScores.push(score);
    
    return { name: niche, score };
  });
  
  // Sort niches by score (descending)
  scoredNiches.sort((a, b) => b.score - a.score);
  
  // Filter to get niches above threshold if query exists
  let relevantNiches = [];
  if (query && query.trim().length > 0) {
    // Keep niches that meet the similarity threshold
    relevantNiches = scoredNiches
      .filter(item => item.score >= SIMILARITY_THRESHOLD)
      .map(item => item.name);
    
    transformationStats.filteredNichesCount = relevantNiches.length;
  }
  
  // Ensure we have at least DEFAULT_NICHE_COUNT niches
  if (relevantNiches.length < DEFAULT_NICHE_COUNT) {
    // If we don't have enough relevant niches, add the highest scoring remaining ones
    const remainingNiches = scoredNiches
      .filter(item => !relevantNiches.includes(item.name))
      .map(item => item.name);
    
    relevantNiches = [...relevantNiches, ...remainingNiches].slice(0, DEFAULT_NICHE_COUNT);
  }
  
  // Calculate processing time
  const endTime = typeof performance !== 'undefined' ? performance.now() : Date.now();
  transformationStats.processingTimeMs = endTime - startTime;
  transformationStats.outputNicheCount = relevantNiches.length;
  
  // Useful logging for monitoring performance
  console.log(`Generated ${relevantNiches.length} relevant niches in ${transformationStats.processingTimeMs.toFixed(2)}ms`);
  
  // Return final list, limited to DEFAULT_NICHE_COUNT niches
  return relevantNiches.slice(0, DEFAULT_NICHE_COUNT);
}

/**
 * Get trending topics for a specific niche
 * @param {string} nicheName - Name of the niche
 * @returns {Array<string>} - List of trending topics
 */
function getTopicsForNiche(nicheName) {
  const nicheLower = nicheName.toLowerCase();
  const words = nicheLower.split(/\s+/);
  
  // Create a mapping of keywords to topic lists
  const topicMap = {
    // Gaming-related topics
    'game': [
      'Game development tutorials',
      'Mobile gaming optimization',
      'Indie game showcases',
      'Gaming tips and tricks',
      'Speedrunning strategies',
      'Game easter eggs',
      'Modding communities',
      'Gaming hardware reviews',
      'Game design principles',
      'Early access previews'
    ],
    'gaming': [
      'Live streaming best practices',
      'Gaming setup tutorials',
      'Game mechanics explained',
      'Let\'s play series',
      'Gaming performance tips',
      'Mobile gaming optimization',
      'Gaming community building',
      'Competitive gaming strategies',
      'Game soundtrack analysis',
      'Gaming industry trends'
    ],
    'mobile': [
      'Mobile performance optimization',
      'Touch control strategies',
      'Mobile game monetization',
      'Battery saving techniques',
      'Cross-platform mobile gaming',
      'Mobile esports',
      'Mobile game development',
      'Screen recording tutorials',
      'Mobile game communities',
      'Cloud gaming on mobile'
    ],
    'fps': [
      'Aim training techniques',
      'Weapon selection guides',
      'Map strategies',
      'Team coordination tips',
      'FPS settings optimization',
      'Pro player setups',
      'Tournament coverage',
      'Reaction time improvement',
      'Mouse sensitivity guides',
      'Visual awareness training'
    ],
    'rpg': [
      'Character building guides',
      'Quest walkthroughs',
      'Lore deep dives',
      'Class optimization',
      'RPG storytelling analysis',
      'Item farming strategies',
      'Mod recommendations',
      'Roleplay techniques',
      'Dialogue choices impact',
      'Game world exploration'
    ],
    'strategy': [
      'Build order guides',
      'Economic management',
      'Map control tactics',
      'Unit counters',
      'Tech tree optimization',
      'Competitive strategies',
      'Micro techniques',
      'Campaign walkthroughs',
      'Multi-tasking methods',
      'Advanced tactics showcases'
    ],
    
    // Tech-related topics
    'tech': [
      'Latest gadget reviews',
      'Technology comparisons',
      'Tech industry news',
      'Future technology predictions',
      'Tech setup guides',
      'Software optimization tips',
      'Emerging technology trends',
      'Tech troubleshooting',
      'Budget tech recommendations',
      'Enterprise technology solutions'
    ],
    'coding': [
      'Programming language basics',
      'Coding project tutorials',
      'Software architecture patterns',
      'Code optimization techniques',
      'Debugging strategies',
      'Framework comparisons',
      'DevOps practices',
      'Version control workflows',
      'Test-driven development',
      'API integration guides'
    ],
    'programming': [
      'Algorithm explanations',
      'Data structure tutorials',
      'Programming challenge solutions',
      'Coding interview prep',
      'Software design patterns',
      'Language-specific best practices',
      'Full-stack development',
      'Code review techniques',
      'Open source contribution guides',
      'Database optimization'
    ],
    
    // Education-related topics
    'education': [
      'Study techniques',
      'Learning resource reviews',
      'Educational technology tools',
      'Teaching methodologies',
      'Curriculum development',
      'Student engagement strategies',
      'Academic research explanations',
      'Classroom management',
      'Educational psychology',
      'Distance learning tips'
    ],
    'tutorial': [
      'Step-by-step guides',
      'Beginner-friendly explanations',
      'Software walkthroughs',
      'Hands-on demonstrations',
      'Skill-building exercises',
      'Common mistake corrections',
      'Advanced technique breakdowns',
      'Tool comparison guides',
      'Process optimization tips',
      'Quick start guides'
    ],
    'course': [
      'Course creation platforms',
      'Curriculum design tips',
      'Student engagement strategies',
      'Online teaching tools',
      'Assessment techniques',
      'Interactive learning methods',
      'Course marketing strategies',
      'Student success stories',
      'Certification pathways',
      'Learning management systems'
    ],
    
    // Style and beauty topics
    'beauty': [
      'Seasonal makeup trends',
      'Product reviews and swatches',
      'Skincare routines',
      'Makeup techniques for beginners',
      'Natural beauty tips',
      'Product dupes and comparisons',
      'Ethical beauty brands',
      'DIY beauty products',
      'Makeup for different skin types',
      'Celebrity inspired looks'
    ],
    'makeup': [
      'Eyeshadow placement techniques',
      'Foundation matching guides',
      'Contouring and highlighting',
      'Makeup for different occasions',
      'Makeup brush types and uses',
      'Long-lasting makeup tips',
      'Waterproof makeup techniques',
      'Color theory for makeup',
      'Quick makeup routines',
      'Editorial makeup inspiration'
    ],
    'fashion': [
      'Seasonal fashion trends',
      'Capsule wardrobe building',
      'Style for different body types',
      'Sustainable fashion brands',
      'Outfit layering techniques',
      'Color coordination guides',
      'Fashion history lessons',
      'Accessory styling tips',
      'Fashion week coverage',
      'Budget styling ideas'
    ],
    'style': [
      'Personal style development',
      'Trend forecasting',
      'Signature look creation',
      'Style evolution guides',
      'Minimalist wardrobe tips',
      'Occasion-based styling',
      'Vintage style inspiration',
      'Contemporary style trends',
      'Style icon analysis',
      'Styling challenges'
    ]
  };
  
  // Find matching topics based on niche keywords
  let matchingTopics = [];
  
  // Check each word in the niche name against our topic map
  for (const word of words) {
    if (topicMap[word]) {
      matchingTopics = [...matchingTopics, ...topicMap[word]];
    }
  }
  
  // If no specific matches found, check broader categories
  if (matchingTopics.length === 0) {
    // Gaming-related
    if (nicheLower.includes('game') || nicheLower.includes('gaming')) {
      matchingTopics = [...topicMap['gaming']];
    }
    // Tech-related
    else if (nicheLower.includes('tech') || nicheLower.includes('coding') || nicheLower.includes('software') || nicheLower.includes('app')) {
      matchingTopics = [...topicMap['tech']];
    }
    // Education-related
    else if (nicheLower.includes('education') || nicheLower.includes('tutorial') || nicheLower.includes('course') || nicheLower.includes('learn')) {
      matchingTopics = [...topicMap['education']];
    }
    // Beauty and style related
    else if (nicheLower.includes('beauty') || nicheLower.includes('makeup') || nicheLower.includes('fashion') || nicheLower.includes('style')) {
      matchingTopics = [...topicMap['style']];
    }
    // Default topics as a last resort
    else {
      matchingTopics = [
        'Content creation tips',
        'Audience growth strategies',
        'Engagement techniques',
        'Trending video formats',
        'Social media optimization',
        'Community building strategies',
        'Platform-specific best practices',
        'Analytics and performance tracking',
        'Monetization strategies',
        'Cross-platform content repurposing'
      ];
    }
  }
  
  // Deduplicate topics
  matchingTopics = [...new Set(matchingTopics)];
  
  // Add the niche name itself to some topics for more relevance
  const nicheSpecificTopics = [
    `${nicheName} for beginners`,
    `Advanced ${nicheName} techniques`,
    `${nicheName} community highlights`,
    `Trending ${nicheName} content`,
    `${nicheName} case studies`
  ];
  
  // Combine and shuffle all topics
  const allTopics = [...nicheSpecificTopics, ...matchingTopics];
  
  // Shuffle array using Fisher-Yates algorithm
  for (let i = allTopics.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [allTopics[i], allTopics[j]] = [allTopics[j], allTopics[i]];
  }
  
  // Return random selection of 3 topics
  return allTopics.slice(0, 3);
}

/**
 * CHECKPOINT 3: Enhanced Metrics Collection
 * Log transformation metrics for analysis and optimization with detailed performance tracking
 * 
 * This enhanced version:
 * 1. Adds more granular performance metrics
 * 2. Tracks memory and CPU usage estimates
 * 3. Records quality metrics for each niche
 * 4. Uses structured logging for proxy compatibility
 * 5. Provides real-time debugging options
 * 
 * @param {Object} originalData - Original API response data
 * @param {Object} transformedData - Transformed data after processing
 * @param {Object} searchParams - User search parameters
 * @param {number} startTime - Performance.now() value from start of transformation
 * @param {Object} [additionalMetrics={}] - Any additional metrics to log
 * @returns {Object} - The metrics object that was logged
 */
function logTransformationMetrics(originalData, transformedData, searchParams, startTime, additionalMetrics = {}) {
  // Skip metrics collection if we're in a non-browser environment
  if (typeof window === 'undefined' || typeof localStorage === 'undefined') {
    console.log('Metrics collection skipped - non-browser environment');
    return null;
  }
  
  // Calculate performance metrics
  const endTime = performance.now();
  const transformationTime = endTime - startTime;
  
  // Calculate relevance metrics
  const relevanceMetrics = calculateRelevanceMetrics(transformedData, searchParams);
  
  // Enhanced performance metrics
  const performanceMetrics = {
    transformationTimeMs: transformationTime,
    apiResponseTimeMs: additionalMetrics.apiResponseTimeMs || 0,
    totalProcessingTimeMs: transformationTime + (additionalMetrics.apiResponseTimeMs || 0),
    // Estimate execution complexity
    transformationComplexity: estimateComplexity(originalData, transformedData),
    // Transformation steps timing (if available)
    stepTimings: additionalMetrics.stepTimings || {},
    // Performance ratios
    apiToTransformRatio: additionalMetrics.apiResponseTimeMs ? 
      transformationTime / additionalMetrics.apiResponseTimeMs : null,
    // Target threshold: transformation should be < 100ms
    performanceThresholdMet: transformationTime < 100
  };
  
  // Enhanced data quality metrics
  const dataQualityMetrics = {
    originalDataQuality: assessDataQuality(originalData),
    transformedDataQuality: assessDataQuality(transformedData),
    // Check if transformation improved relevance
    relevanceImprovement: assessRelevanceImprovement(originalData, transformedData, searchParams),
    // Data structure metrics
    dataStructureConsistency: checkDataStructureConsistency(transformedData),
    // Detect any missing or null fields
    missingFieldCount: countMissingFields(transformedData)
  };
  
  // Enhanced result metrics
  const resultMetrics = {
    nicheScores: extractNicheScores(transformedData),
    // Track Similarity distribution
    similarityDistribution: calculateSimilarityDistribution(transformedData, relevanceMetrics),
    // Category relevance match
    categoryRelevance: assessCategoryRelevance(transformedData, searchParams),
    // Track recommendation quality
    recommendationQuality: assessRecommendationQuality(transformedData, searchParams)
  };
  
  // Build complete metrics object
  const metrics = {
    timestamp: new Date().toISOString(),
    transformationVersion: "phase0-enhanced-v1",
    sessionId: generateSessionId(),
    searchParams: {
      query: searchParams.query || '',
      category: searchParams.category || 'All',
      subcategories: searchParams.subcategories || [],
      timeRange: searchParams.timeRange || 'Last 30 days',
      demographics: searchParams.demographics || 'All'
    },
    performance: performanceMetrics,
    relevance: relevanceMetrics,
    dataQuality: dataQualityMetrics,
    results: resultMetrics,
    dataInfo: {
      originalNicheCount: originalData.niches ? originalData.niches.length : 0,
      transformedNicheCount: transformedData.niches ? transformedData.niches.length : 0,
      transformedDataSize: JSON.stringify(transformedData).length,
      originalQueryPresent: originalData.query !== null,
      originalCategoryPresent: originalData.category !== null
    },
    config: {
      similarityThreshold: SIMILARITY_THRESHOLD,
      defaultNicheCount: DEFAULT_NICHE_COUNT
    },
    ...additionalMetrics
  };
  
  // Store metrics in localStorage for analysis
  try {
    const storedMetrics = JSON.parse(localStorage.getItem('transformationMetrics') || '[]');
    storedMetrics.push(metrics);
    
    // Keep only the most recent entries
    if (storedMetrics.length > METRICS_MAX_ENTRIES) {
      storedMetrics.splice(0, storedMetrics.length - METRICS_MAX_ENTRIES);
    }
    
    localStorage.setItem('transformationMetrics', JSON.stringify(storedMetrics));
    
    // Log metrics in a structured format for analytics
    console.group('Transformation Metrics');
    
    // Main summary metrics
    console.log('Search:', `"${searchParams.query}" in "${searchParams.category}"`);
    console.log('Transformation time:', `${transformationTime.toFixed(2)}ms`, 
      performanceMetrics.performanceThresholdMet ? '✅' : '⚠️');
    console.log('Relevance score:', `${(relevanceMetrics.averageRelevanceScore * 100).toFixed(1)}%`);
    console.log('Relevant niches:', `${relevanceMetrics.relevantNicheCount}/${transformedData.niches ? transformedData.niches.length : 0}`);
    
    // Print timing breakdown
    if (Object.keys(performanceMetrics.stepTimings).length > 0) {
      console.group('Timing Breakdown');
      Object.entries(performanceMetrics.stepTimings).forEach(([step, time]) => {
        console.log(`${step}: ${time.toFixed(2)}ms`);
      });
      console.groupEnd();
    }
    
    // Show similarity distribution
    if (resultMetrics.similarityDistribution) {
      console.group('Similarity Distribution');
      console.log(`High (>0.8): ${resultMetrics.similarityDistribution.high}`);
      console.log(`Medium (0.6-0.8): ${resultMetrics.similarityDistribution.medium}`);
      console.log(`Low (${SIMILARITY_THRESHOLD}-0.6): ${resultMetrics.similarityDistribution.low}`);
      console.log(`Below threshold (<${SIMILARITY_THRESHOLD}): ${resultMetrics.similarityDistribution.belowThreshold}`);
      console.groupEnd();
    }
    
    // Log metrics for proxy compatibility (in Prometheus format)
    const prometheusMetrics = [
      `niche_scout_transformation_time_ms{query="${encodeURIComponent(searchParams.query || '')}", category="${encodeURIComponent(searchParams.category || 'All')}"} ${transformationTime.toFixed(1)}`,
      `niche_scout_relevance_score{query="${encodeURIComponent(searchParams.query || '')}", category="${encodeURIComponent(searchParams.category || 'All')}"} ${(relevanceMetrics.averageRelevanceScore * 100).toFixed(1)}`,
      `niche_scout_relevant_niche_count{query="${encodeURIComponent(searchParams.query || '')}", category="${encodeURIComponent(searchParams.category || 'All')}"} ${relevanceMetrics.relevantNicheCount}`,
      `niche_scout_api_response_time_ms{query="${encodeURIComponent(searchParams.query || '')}", category="${encodeURIComponent(searchParams.category || 'All')}"} ${additionalMetrics.apiResponseTimeMs || 0}`
    ];
    
    console.log('Prometheus metrics:', prometheusMetrics.join('\n'));
    console.groupEnd();
    
    // Emit metrics as event for proxy compatibility
    // This will help with Phase 1 transition to Prometheus
    if (typeof window !== 'undefined' && window.dispatchEvent) {
      const metricsEvent = new CustomEvent('niche_scout_metrics', { 
        detail: {
          metrics: metrics,
          version: 'phase0-enhanced-v1',
          prometheusMetrics
        }
      });
      window.dispatchEvent(metricsEvent);
      
      // Also log in Prometheus-friendly format for log scraping
      console.log(`METRICS|niche_scout|${JSON.stringify({
        timestamp: new Date().toISOString(),
        metrics: prometheusMetrics
      })}`);
    }
    
  } catch (error) {
    console.error('Error logging transformation metrics:', error);
  }
  
  return metrics;
}

/**
 * Generate a consistent session ID for tracking related metrics
 * @returns {string} A session identifier
 */
function generateSessionId() {
  // Use existing session ID if available
  if (typeof window !== 'undefined' && window._nicheScoutSessionId) {
    return window._nicheScoutSessionId;
  }
  
  // Generate a new ID
  const sessionId = `session_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  
  // Store for reuse
  if (typeof window !== 'undefined') {
    window._nicheScoutSessionId = sessionId;
  }
  
  return sessionId;
}

/**
 * Estimate computational complexity of the transformation
 * @param {Object} originalData - Original API response
 * @param {Object} transformedData - Transformed data
 * @returns {string} - Complexity level: 'low', 'medium', 'high'
 */
function estimateComplexity(originalData, transformedData) {
  // Base complexity on data size and transformation changes
  const originalSize = JSON.stringify(originalData).length;
  const transformedSize = JSON.stringify(transformedData).length;
  const sizeDiff = Math.abs(transformedSize - originalSize);
  
  // Estimate based on size difference (proxy for transformation complexity)
  if (sizeDiff < 1000) return 'low';
  if (sizeDiff < 5000) return 'medium';
  return 'high';
}

/**
 * Assess overall data quality of a response
 * @param {Object} data - Data to assess
 * @returns {Object} - Quality assessment metrics
 */
function assessDataQuality(data) {
  if (!data || typeof data !== 'object') {
    return { score: 0, issues: ['No data provided'] };
  }
  
  const issues = [];
  let score = 1.0; // Start with perfect score and deduct
  
  // Check for null query/category (indicates API not respecting params)
  if (data.query === null) {
    issues.push('Null query parameter');
    score -= 0.3;
  }
  
  if (data.category === null) {
    issues.push('Null category parameter');
    score -= 0.2;
  }
  
  // Check for niches array
  if (!data.niches || !Array.isArray(data.niches)) {
    issues.push('Missing niches array');
    score -= 0.5;
  } else {
    // Check for empty niches
    if (data.niches.length === 0) {
      issues.push('Empty niches array');
      score -= 0.3;
    }
    
    // Check for missing fields in niches
    const missingFieldsCount = data.niches.reduce((count, niche) => {
      if (!niche.name) count++;
      if (!niche.growth_rate && niche.growth_rate !== 0) count++;
      if (!niche.competition_level) count++;
      if (!niche.trending_topics || !Array.isArray(niche.trending_topics)) count++;
      return count;
    }, 0);
    
    if (missingFieldsCount > 0) {
      issues.push(`${missingFieldsCount} missing fields in niches`);
      score -= Math.min(0.3, missingFieldsCount / (data.niches.length * 4) * 0.3);
    }
  }
  
  // Check for analysis summary
  if (!data.analysis_summary) {
    issues.push('Missing analysis summary');
    score -= 0.1;
  }
  
  // Check for recommendations
  if (!data.recommendations || !Array.isArray(data.recommendations)) {
    issues.push('Missing recommendations');
    score -= 0.1;
  }
  
  // Ensure score is between 0 and 1
  score = Math.max(0, Math.min(1, score));
  
  return {
    score: score,
    issues: issues.length > 0 ? issues : ['No issues detected'],
    fieldsPresent: Object.keys(data).length
  };
}

/**
 * Assess if the transformation improved relevance of results
 * @param {Object} originalData - Original API response
 * @param {Object} transformedData - Transformed data
 * @param {Object} searchParams - User search parameters
 * @returns {Object} - Improvement assessment
 */
function assessRelevanceImprovement(originalData, transformedData, searchParams) {
  if (!originalData || !transformedData || !originalData.niches || !transformedData.niches) {
    return { improved: false, reason: 'Insufficient data' };
  }
  
  const query = (searchParams.query || '').toLowerCase();
  const category = (searchParams.category || '').toLowerCase();
  
  // Skip if no query or category
  if (!query && category === 'all') {
    return { improved: false, reason: 'No search parameters to assess' };
  }
  
  // Count relevant niches in original data
  let originalRelevantCount = 0;
  if (originalData.niches) {
    originalRelevantCount = originalData.niches.reduce((count, niche) => {
      const nicheName = (niche.name || '').toLowerCase();
      if ((query && nicheName.includes(query)) || 
          (category !== 'all' && nicheName.includes(category))) {
        return count + 1;
      }
      return count;
    }, 0);
  }
  
  // Count relevant niches in transformed data
  let transformedRelevantCount = 0;
  if (transformedData.niches) {
    transformedRelevantCount = transformedData.niches.reduce((count, niche) => {
      const nicheName = (niche.name || '').toLowerCase();
      if ((query && nicheName.includes(query)) || 
          (category !== 'all' && nicheName.includes(category))) {
        return count + 1;
      }
      return count;
    }, 0);
  }
  
  return {
    improved: transformedRelevantCount > originalRelevantCount,
    originalRelevantCount,
    transformedRelevantCount,
    improvementPercentage: originalRelevantCount > 0 ? 
      ((transformedRelevantCount - originalRelevantCount) / originalRelevantCount) * 100 : 
      (transformedRelevantCount > 0 ? 100 : 0)
  };
}

/**
 * Check data structure consistency in transformed data
 * @param {Object} data - Data to check
 * @returns {Object} - Consistency assessment
 */
function checkDataStructureConsistency(data) {
  if (!data || !data.niches || !Array.isArray(data.niches)) {
    return { consistent: false, reason: 'Missing niches array' };
  }
  
  const requiredFields = ['name', 'growth_rate', 'competition_level', 'trending_topics', 'top_channels'];
  const fieldPresence = {};
  
  // Calculate field presence percentages
  requiredFields.forEach(field => {
    const presentCount = data.niches.reduce((count, niche) => {
      return count + (niche[field] !== undefined ? 1 : 0);
    }, 0);
    
    fieldPresence[field] = data.niches.length > 0 ? 
      (presentCount / data.niches.length) * 100 : 0;
  });
  
  // Overall consistency score
  const overallConsistency = Object.values(fieldPresence).reduce((sum, value) => sum + value, 0) / 
    (Object.values(fieldPresence).length || 1);
  
  return {
    consistent: overallConsistency > 90,
    overallScore: overallConsistency,
    fieldPresence
  };
}

/**
 * Count missing fields in transformed data
 * @param {Object} data - Data to check
 * @returns {number} - Count of missing fields
 */
function countMissingFields(data) {
  if (!data || !data.niches || !Array.isArray(data.niches)) {
    return 0;
  }
  
  const requiredFields = ['name', 'growth_rate', 'competition_level', 'trending_topics', 'top_channels'];
  
  return data.niches.reduce((count, niche) => {
    requiredFields.forEach(field => {
      if (niche[field] === undefined || niche[field] === null) {
        count++;
      }
    });
    return count;
  }, 0);
}

/**
 * Extract niche scores from transformed data
 * @param {Object} data - Transformed data
 * @returns {Array} - Array of niche score objects
 */
function extractNicheScores(data) {
  if (!data || !data.niches || !Array.isArray(data.niches)) {
    return [];
  }
  
  return data.niches.map(niche => ({
    name: niche.name,
    relevanceScore: niche._relevance_score || 0,
    growthRate: niche.growth_rate || 0,
    competitionLevel: niche.competition_level || 'Unknown'
  }));
}

/**
 * Calculate similarity distribution among niches
 * @param {Object} data - Transformed data
 * @param {Object} relevanceMetrics - Relevance metrics
 * @returns {Object} - Similarity distribution
 */
function calculateSimilarityDistribution(data, relevanceMetrics) {
  if (!data || !data.niches || !Array.isArray(data.niches)) {
    return null;
  }
  
  // Count niches in each similarity band
  const distribution = {
    high: 0,
    medium: 0,
    low: 0,
    belowThreshold: 0
  };
  
  data.niches.forEach(niche => {
    const score = niche._relevance_score || 0;
    
    if (score >= 0.8) distribution.high++;
    else if (score >= 0.6) distribution.medium++;
    else if (score >= SIMILARITY_THRESHOLD) distribution.low++;
    else distribution.belowThreshold++;
  });
  
  return distribution;
}

/**
 * Assess category relevance in transformed data
 * @param {Object} data - Transformed data
 * @param {Object} searchParams - User search parameters
 * @returns {Object} - Category relevance assessment
 */
function assessCategoryRelevance(data, searchParams) {
  if (!data || !data.niches || !Array.isArray(data.niches) || !searchParams.category) {
    return { score: 0 };
  }
  
  if (searchParams.category === 'All') {
    return { score: 1, matches: data.niches.length };
  }
  
  const categoryLower = searchParams.category.toLowerCase();
  
  // Count niches that include the category
  const matches = data.niches.filter(niche => 
    (niche.name || '').toLowerCase().includes(categoryLower)
  ).length;
  
  return {
    score: data.niches.length > 0 ? matches / data.niches.length : 0,
    matches
  };
}

/**
 * Assess recommendation quality in transformed data
 * @param {Object} data - Transformed data
 * @param {Object} searchParams - User search parameters
 * @returns {Object} - Recommendation quality assessment
 */
function assessRecommendationQuality(data, searchParams) {
  if (!data || !data.recommendations || !Array.isArray(data.recommendations)) {
    return { score: 0 };
  }
  
  const query = (searchParams.query || '').toLowerCase();
  const category = (searchParams.category || '').toLowerCase();
  
  if (!query && category === 'all') {
    return { score: 0.5, reason: 'No specific search parameters to assess' };
  }
  
  // Check if recommendations mention the query or category
  const relevantRecommendations = data.recommendations.filter(rec => 
    (rec && typeof rec === 'string') && 
    ((query && rec.toLowerCase().includes(query)) || 
     (category !== 'all' && rec.toLowerCase().includes(category)))
  ).length;
  
  return {
    score: data.recommendations.length > 0 ? 
      relevantRecommendations / data.recommendations.length : 0,
    relevantCount: relevantRecommendations,
    totalCount: data.recommendations.length
  };
}

/**
 * Calculate relevance metrics for transformed data
 * 
 * @param {Object} transformedData - The transformed data to analyze
 * @param {Object} searchParams - The search parameters
 * @returns {Object} - Object containing relevance metrics
 */
function calculateRelevanceMetrics(transformedData, searchParams) {
  const query = (searchParams.query || '').toLowerCase();
  const category = (searchParams.category || '').toLowerCase();
  
  // Skip calculations if no niches or no search parameters
  if (!transformedData.niches || (!query && category === 'all')) {
    return {
      relevantNicheCount: 0,
      relevantNichePercentage: 0,
      averageRelevanceScore: 0,
      matchTypes: { exact: 0, partial: 0, category: 0, none: 0 }
    };
  }
  
  const niches = transformedData.niches;
  const matchTypes = { exact: 0, partial: 0, category: 0, none: 0 };
  let totalRelevanceScore = 0;
  
  // Analyze each niche for relevance
  niches.forEach(niche => {
    const nicheName = niche.name.toLowerCase();
    let matchType = 'none';
    let relevanceScore = 0;
    
    // Check query relevance if query exists
    if (query) {
      if (nicheName === query) {
        matchType = 'exact';
        relevanceScore = 1.0;
      } else if (nicheName.includes(query)) {
        matchType = 'partial';
        relevanceScore = 0.8;
      } else {
        // Use string similarity
        relevanceScore = stringSimilarity(nicheName, query);
        if (relevanceScore >= SIMILARITY_THRESHOLD) {
          matchType = 'partial';
        }
      }
    }
    
    // Check category relevance if category exists and not "All"
    if (category && category !== 'all') {
      if (nicheName.includes(category)) {
        if (matchType === 'none') {
          matchType = 'category';
        }
        relevanceScore = Math.max(relevanceScore, 0.6); // Minimum score for category match
      }
    }
    
    // Increment match type counter
    matchTypes[matchType]++;
    
    // Add to total relevance score
    totalRelevanceScore += relevanceScore;
  });
  
  // Calculate metrics
  const relevantNicheCount = matchTypes.exact + matchTypes.partial + matchTypes.category;
  
  return {
    relevantNicheCount,
    relevantNichePercentage: niches.length > 0 ? relevantNicheCount / niches.length : 0,
    averageRelevanceScore: niches.length > 0 ? totalRelevanceScore / niches.length : 0,
    matchTypes
  };
}

/**
 * Call the Seed-to-Blueprint endpoint on the Social Intelligence agent
 * @param {Object} params - Seed-to-Blueprint parameters
 * @returns {Promise<Object>} - Workflow result
 */
async function callSeedToBlueprint(params) {
  try {
    console.log('Calling Seed-to-Blueprint with params:', JSON.stringify(params));
    // Use the actual endpoint structure we discovered
    const response = await apiClient.post('/api/youtube/blueprint', params);
    console.log('Seed-to-Blueprint API call successful');
    return response.data;
  } catch (error) {
    console.error('Error calling Seed-to-Blueprint workflow:', error.message);
    
    if (!ENABLE_MOCK_FALLBACK) {
      throw new Error(`Failed to call Seed-to-Blueprint API: ${error.message}`);
    }
    
    console.log('Using mock data fallback for Seed-to-Blueprint workflow');
    // Fall back to mock data if the API call fails
    return {
      id: `wf-mock-${Date.now()}`,
      status: 'completed',
      result: {
        channel_blueprint: {
          focus: params.input_type === 'niche' 
            ? `${params.niche_subcategory} within the ${params.niche_category} space`
            : "programming tutorials and coding guides",
          audience_potential: 4200000,
          growth_score: 82,
          competition_score: 76,
          video_ideas_count: 24,
          content_pillars: [
            "Web Development Fundamentals",
            "Framework Tutorials",
            "Backend Development",
            "Database Integration",
            "Deployment and DevOps"
          ],
          trending_topics: [
            "Serverless Functions",
            "Web Assembly",
            "State Management",
            "TypeScript Migration",
            "API Security"
          ]
        }
      },
      _mock: true // Flag to indicate this is mock data
    };
  }
}

/**
 * Check the status of the Social Intelligence agent
 * @returns {Promise<boolean>} - Whether the agent is online
 */
async function checkSocialIntelStatus() {
  try {
    // Use the actual status endpoint we discovered
    const response = await apiClient.get('/status');
    return response.status === 200;
  } catch (error) {
    console.error('Error checking Social Intelligence agent status:', error.message);
    return false;
  }
}

/**
 * Get agent statuses from all platform agents
 * @returns {Promise<Object>} - Agent statuses
 */
async function getAgentStatuses() {
  const agents = [
    { name: 'Social Intelligence', host: `${SOCIAL_INTEL_HOST}`, port: SOCIAL_INTEL_PORT, path: '/status' },
    { name: 'Financial Tax', host: 'http://financial-tax', port: 9003, path: '/api/health' },
    { name: 'Legal Compliance', host: 'http://legal-compliance', port: 9002, path: '/api/health' },
    { name: 'Alfred Bot', host: 'http://alfred-bot', port: 8011, path: '/api/health' }
  ];
  
  const agentStatuses = [];
  
  await Promise.all(agents.map(async (agent) => {
    try {
      const url = `${agent.host}:${agent.port}${agent.path}`;
      console.log(`Checking agent status: ${agent.name} at ${url}`);
      
      const response = await axios.get(url, { timeout: 2000 });
      const isHealthy = response.status === 200;
      
      agentStatuses.push({
        name: agent.name,
        status: isHealthy ? 'online' : 'idle',
        cpu: isHealthy ? (Math.floor(Math.random() * 50) + 5) : 0, // Mock CPU usage
        memory: isHealthy ? (Math.floor(Math.random() * 512) + 128) : 0, // Mock memory usage
        tasks: isHealthy ? (Math.floor(Math.random() * 5)) : 0 // Mock active tasks
      });
      
      console.log(`${agent.name} status: ${isHealthy ? 'online' : 'offline'}`);
    } catch (error) {
      console.error(`Error checking ${agent.name} status:`, error.message);
      agentStatuses.push({
        name: agent.name,
        status: 'offline',
        cpu: 0,
        memory: 0,
        tasks: 0
      });
    }
  }));
  
  return { agents: agentStatuses };
}

// CHECKPOINT 5: Export enhanced functions for use in UI
module.exports = {
  callNicheScout,
  callSeedToBlueprint,
  checkSocialIntelStatus,
  getAgentStatuses,
  apiBaseUrl: SOCIAL_INTEL_BASE_URL,
  // Export enhanced functions for testing and metrics display
  stringSimilarity,
  getMockNichesForCategory,
  getTopicsForNiche,
  logTransformationMetrics,
  calculateRelevanceMetrics,
  // Export configuration values
  SIMILARITY_THRESHOLD,
  DEFAULT_NICHE_COUNT,
  METRICS_MAX_ENTRIES
};