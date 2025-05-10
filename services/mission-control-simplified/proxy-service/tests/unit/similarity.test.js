/**
 * Unit tests for string similarity functions
 */

// Mock config
jest.mock('../../src/config', () => ({
  getConfig: jest.fn(() => ({
    transformation: {
      algorithmWeights: {
        levenshtein: 0.5,
        jaccard: 0.3,
        jaroWinkler: 0.2
      }
    }
  }))
}));

// Mock logger
jest.mock('../../src/utils/logger', () => ({
  createLogger: jest.fn(() => ({
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn()
  }))
}));

const {
  stringSimilarity,
  calculateLevenshtein,
  calculateJaccardSimilarity,
  calculateJaroWinkler,
  commonPrefixLength
} = require('../../src/transformers/similarity');

describe('String Similarity Functions', () => {
  describe('stringSimilarity', () => {
    test('identical strings return 1.0', () => {
      expect(stringSimilarity('test', 'test')).toBe(1.0);
      expect(stringSimilarity('', '')).toBe(1.0);
    });

    test('case insensitive comparison', () => {
      expect(stringSimilarity('TEST', 'test')).toBe(1.0);
      expect(stringSimilarity('Test', 'test')).toBe(1.0);
    });

    test('empty strings edge cases', () => {
      expect(stringSimilarity('test', '')).toBe(0.0);
      expect(stringSimilarity('', 'test')).toBe(0.0);
      expect(stringSimilarity(null, 'test')).toBe(0.0);
      expect(stringSimilarity('test', null)).toBe(0.0);
      expect(stringSimilarity(null, null)).toBe(1.0);
    });

    test('substring matching gets boost', () => {
      const score = stringSimilarity('mobile', 'mobile gaming');
      expect(score).toBeGreaterThan(0.8);
    });

    test('completely different strings have low similarity', () => {
      const score = stringSimilarity('xyzabc', 'mnopqr');
      expect(score).toBeLessThan(0.3);
    });

    test('handles very short strings appropriately', () => {
      expect(stringSimilarity('a', 'a')).toBe(1.0);
      expect(stringSimilarity('ab', 'ac')).toBeLessThan(0.9);
      expect(stringSimilarity('a', 'z')).toBeLessThan(0.5);
    });

    test('similar strings have moderate similarity', () => {
      const score = stringSimilarity('gaming', 'game');
      expect(score).toBeGreaterThan(0.5);
      expect(score).toBeLessThan(0.9);
    });
  });

  describe('calculateLevenshtein', () => {
    test('identical strings have distance 0', () => {
      expect(calculateLevenshtein('test', 'test')).toBe(1.0);
    });

    test('completely different strings have low similarity', () => {
      expect(calculateLevenshtein('abc', 'xyz')).toBeLessThan(0.3);
    });

    test('strings with small edit distance have high similarity', () => {
      expect(calculateLevenshtein('test', 'tent')).toBeGreaterThan(0.7);
    });
  });

  describe('calculateJaccardSimilarity', () => {
    test('identical token sets have similarity 1.0', () => {
      expect(calculateJaccardSimilarity('word1 word2', 'word1 word2')).toBe(1.0);
    });

    test('disjoint token sets have similarity 0.0', () => {
      expect(calculateJaccardSimilarity('word1 word2', 'word3 word4')).toBe(0.0);
    });

    test('partial overlapping sets have fractional similarity', () => {
      expect(calculateJaccardSimilarity('word1 word2 word3', 'word3 word4 word5')).toBeCloseTo(0.2, 1);
    });

    test('handles empty strings appropriately', () => {
      expect(calculateJaccardSimilarity('', 'word1 word2')).toBe(0.0);
      expect(calculateJaccardSimilarity('word1 word2', '')).toBe(0.0);
      expect(calculateJaccardSimilarity('', '')).toBe(0.0);
    });
  });

  describe('calculateJaroWinkler', () => {
    test('identical strings have similarity 1.0', () => {
      expect(calculateJaroWinkler('test', 'test')).toBe(1.0);
    });

    test('similar strings with matching prefix have high similarity', () => {
      expect(calculateJaroWinkler('martha', 'marhta')).toBeGreaterThan(0.9);
    });

    test('completely different strings have low similarity', () => {
      expect(calculateJaroWinkler('abc', 'xyz')).toBeLessThan(0.5);
    });

    test('handles empty strings appropriately', () => {
      expect(calculateJaroWinkler('', '')).toBe(1.0);
      expect(calculateJaroWinkler('test', '')).toBe(0.0);
      expect(calculateJaroWinkler('', 'test')).toBe(0.0);
    });
  });

  describe('commonPrefixLength', () => {
    test('identical strings return full length (up to max)', () => {
      expect(commonPrefixLength('test', 'test')).toBe(4);
      expect(commonPrefixLength('test', 'test', 3)).toBe(3);
    });

    test('different strings return length of common prefix', () => {
      expect(commonPrefixLength('test', 'team')).toBe(2);
      expect(commonPrefixLength('apple', 'application')).toBe(5);
      expect(commonPrefixLength('xyz', 'abc')).toBe(0);
    });
  });
});