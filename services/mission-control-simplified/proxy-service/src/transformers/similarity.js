/**
 * String similarity algorithms for the proxy service
 *
 * Extracted from the client-side implementation with minor adjustments
 * for server-side execution.
 */

const { getConfig } = require('../config');
const { createLogger } = require('../utils/logger');

const logger = createLogger('similarity');

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
  const config = getConfig();
  const { algorithmWeights } = config.transformation;

  // Handle edge cases
  if (!str1 && !str2) return 1.0; // Both empty strings are identical
  if (!str1 || !str2) return 0.0; // One empty string has no similarity

  // Convert to lowercase for case-insensitive comparison
  const s1 = String(str1).toLowerCase();
  const s2 = String(str2).toLowerCase();

  // Special case: identical after normalization
  if (s1 === s2) return 1.0;

  // Special handling for very short strings
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

  // Combine the scores with configurable weights
  const finalScore = (levenshteinSimilarity * algorithmWeights.levenshtein) +
                     (jaccardSimilarity * algorithmWeights.jaccard) +
                     (jaroWinklerSimilarity * algorithmWeights.jaroWinkler);

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

module.exports = {
  stringSimilarity,
  calculateLevenshtein,
  calculateJaccardSimilarity,
  calculateJaroWinkler,
  commonPrefixLength
};
