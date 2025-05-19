/**
 * Topic generation for niches
 *
 * Extracted from the client-side implementation with minor adjustments
 * for server-side execution.
 */

const { createLogger } = require('../utils/logger');
const { getCachedData, cacheData } = require('../services/redis');

const logger = createLogger('topics');

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
 * Get topic map for caching or customization
 * @returns {Promise<Object>} - Topic map object
 */
async function getTopicMap() {
  try {
    // Try to get from Redis first
    const cachedTopicMap = await getCachedData('topic-map');

    if (cachedTopicMap) {
      logger.info('Using cached topic map');
      return cachedTopicMap;
    }

    // If not in cache, use default and store it
    // (Default map is defined in getTopicsForNiche function)
    logger.info('Topic map not found in cache, using default');

    return {};
  } catch (error) {
    logger.error('Error getting topic map', { error: error.message });
    return {};
  }
}

/**
 * Update topic map in cache
 * @param {Object} topicMap - New topic map
 * @returns {Promise<boolean>} - Success status
 */
async function updateTopicMap(topicMap) {
  try {
    await cacheData('topic-map', topicMap, 86400); // 24 hours TTL
    logger.info('Topic map updated in cache');
    return true;
  } catch (error) {
    logger.error('Error updating topic map', { error: error.message });
    return false;
  }
}

module.exports = {
  getTopicsForNiche,
  getTopicMap,
  updateTopicMap
};
