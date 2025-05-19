#!/bin/bash
# Taxonomy Integration Installation Script
# This script installs the centralized taxonomy configuration across both Mission Control and Agent Orchestrator

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Installing Taxonomy Integration ===${NC}"
echo "This script will install the centralized taxonomy configuration across both platforms."

# Project paths
PROJECT_ROOT="/home/locotoki/projects/alfred-agent-platform-v2"
MISSION_CONTROL="${PROJECT_ROOT}/services/mission-control"
AGENT_ORCHESTRATOR="${PROJECT_ROOT}/services/agent-orchestrator"

# Create directories if they don't exist
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p "${MISSION_CONTROL}/src/utils"
mkdir -p "${MISSION_CONTROL}/src/components/workflows"

# Copy centralized taxonomy to Agent Orchestrator
echo -e "${YELLOW}Installing shared taxonomy in Agent Orchestrator...${NC}"
cat > "${AGENT_ORCHESTRATOR}/src/config/taxonomy.ts" << 'EOL'
import { Category } from "@/types/niche-scout";

export const categories: Category[] = [
  { label: "Education & Learning", value: "education" },
  { label: "Entertainment", value: "entertainment" },
  { label: "Technology & Gaming", value: "tech" },
  { label: "Lifestyle & Health", value: "lifestyle" },
  { label: "Business & Finance", value: "business" },
  { label: "Arts & Creativity", value: "arts" },
  { label: "Travel & Adventure", value: "travel" },
  { label: "Sports & Fitness", value: "sports" },
  { label: "Kids & Family", value: "kids" },
];

export const subcategoryMap: Record<string, Category[]> = {
  education: [
    { label: "Online Courses & Tutorials", value: "education.courses" },
    { label: "Language Learning", value: "education.language" },
    { label: "Science & Explainers", value: "education.science" },
    { label: "History & Culture", value: "education.history" },
    { label: "DIY Skills & How-To", value: "education.diy" },
    { label: "Career Development", value: "education.career" },
  ],
  entertainment: [
    { label: "Comedy & Sketches", value: "entertainment.comedy" },
    { label: "Reaction Videos", value: "entertainment.reaction" },
    { label: "Music & Music Videos", value: "entertainment.music" },
    { label: "Movie & TV Reviews", value: "entertainment.reviews" },
    { label: "Vlogging & Daily Life", value: "entertainment.vlogs" },
    { label: "Animation & Cartoons", value: "entertainment.animation" },
  ],
  tech: [
    { label: "Smartphones & Gadgets", value: "tech.gadgets" },
    { label: "PC & Console Gaming", value: "tech.gaming" },
    { label: "Programming & Development", value: "tech.programming" },
    { label: "AI & Machine Learning", value: "tech.ai" },
    { label: "Crypto & Blockchain", value: "tech.crypto" },
    { label: "Tech News & Reviews", value: "tech.news" },
  ],
  lifestyle: [
    { label: "Fashion & Style", value: "lifestyle.fashion" },
    { label: "Health & Wellness", value: "lifestyle.health" },
    { label: "Beauty & Skincare", value: "lifestyle.beauty" },
    { label: "Home Decor & Design", value: "lifestyle.home" },
    { label: "Food & Cooking", value: "lifestyle.food" },
    { label: "Personal Development", value: "lifestyle.development" },
  ],
  business: [
    { label: "Entrepreneurship", value: "business.entrepreneurship" },
    { label: "Stock Market & Investing", value: "business.investing" },
    { label: "Real Estate", value: "business.realestate" },
    { label: "Digital Marketing", value: "business.marketing" },
    { label: "Freelancing & Side Hustles", value: "business.freelancing" },
    { label: "Career Advice", value: "business.career" },
  ],
  arts: [
    { label: "Digital Art & Design", value: "arts.digital" },
    { label: "Music Production", value: "arts.music" },
    { label: "Photography & Videography", value: "arts.photography" },
    { label: "Drawing & Painting", value: "arts.drawing" },
    { label: "Crafts & DIY", value: "arts.crafts" },
    { label: "Writing & Storytelling", value: "arts.writing" },
  ],
  travel: [
    { label: "Travel Vlogging", value: "travel.vlogging" },
    { label: "Budget Travel & Hacks", value: "travel.budget" },
    { label: "Food Tourism", value: "travel.food" },
    { label: "Adventure & Outdoor", value: "travel.adventure" },
    { label: "Digital Nomad Lifestyle", value: "travel.nomad" },
    { label: "Solo Travel", value: "travel.solo" },
  ],
  sports: [
    { label: "Fitness & Workouts", value: "sports.fitness" },
    { label: "Sports Commentary", value: "sports.commentary" },
    { label: "Extreme Sports", value: "sports.extreme" },
    { label: "Outdoor Recreation", value: "sports.outdoor" },
    { label: "Combat Sports & Martial Arts", value: "sports.combat" },
    { label: "Sports Highlights & Analysis", value: "sports.analysis" },
  ],
  kids: [
    { label: "Nursery Rhymes & Songs", value: "kids.nursery" },
    { label: "Educational Cartoons", value: "kids.educational" },
    { label: "Toys & Unboxing", value: "kids.toys" },
    { label: "Crafts & Activities", value: "kids.crafts" },
    { label: "Bedtime Stories", value: "kids.stories" },
    { label: "Family Vlogs", value: "kids.family" },
  ],
};
EOL

# Install shared taxonomy in Mission Control
echo -e "${YELLOW}Installing shared taxonomy in Mission Control...${NC}"
cat > "${MISSION_CONTROL}/src/utils/shared-taxonomy.ts" << 'EOL'
/**
 * Shared Taxonomy Configuration
 *
 * This file centralizes taxonomy settings used across both Mission Control UI (port 3007)
 * and Social Intelligence Agent (port 8080).
 */

export interface Category {
  label: string;
  value: string;
}

export const categories: Category[] = [
  { label: "Education & Learning", value: "education" },
  { label: "Entertainment", value: "entertainment" },
  { label: "Technology & Gaming", value: "tech" },
  { label: "Lifestyle & Health", value: "lifestyle" },
  { label: "Business & Finance", value: "business" },
  { label: "Arts & Creativity", value: "arts" },
  { label: "Travel & Adventure", value: "travel" },
  { label: "Sports & Fitness", value: "sports" },
  { label: "Kids & Family", value: "kids" },
];

export const subcategoryMap: Record<string, Category[]> = {
  education: [
    { label: "Online Courses & Tutorials", value: "education.courses" },
    { label: "Language Learning", value: "education.language" },
    { label: "Science & Explainers", value: "education.science" },
    { label: "History & Culture", value: "education.history" },
    { label: "DIY Skills & How-To", value: "education.diy" },
    { label: "Career Development", value: "education.career" },
  ],
  entertainment: [
    { label: "Comedy & Sketches", value: "entertainment.comedy" },
    { label: "Reaction Videos", value: "entertainment.reaction" },
    { label: "Music & Music Videos", value: "entertainment.music" },
    { label: "Movie & TV Reviews", value: "entertainment.reviews" },
    { label: "Vlogging & Daily Life", value: "entertainment.vlogs" },
    { label: "Animation & Cartoons", value: "entertainment.animation" },
  ],
  tech: [
    { label: "Smartphones & Gadgets", value: "tech.gadgets" },
    { label: "PC & Console Gaming", value: "tech.gaming" },
    { label: "Programming & Development", value: "tech.programming" },
    { label: "AI & Machine Learning", value: "tech.ai" },
    { label: "Crypto & Blockchain", value: "tech.crypto" },
    { label: "Tech News & Reviews", value: "tech.news" },
  ],
  lifestyle: [
    { label: "Fashion & Style", value: "lifestyle.fashion" },
    { label: "Health & Wellness", value: "lifestyle.health" },
    { label: "Beauty & Skincare", value: "lifestyle.beauty" },
    { label: "Home Decor & Design", value: "lifestyle.home" },
    { label: "Food & Cooking", value: "lifestyle.food" },
    { label: "Personal Development", value: "lifestyle.development" },
  ],
  business: [
    { label: "Entrepreneurship", value: "business.entrepreneurship" },
    { label: "Stock Market & Investing", value: "business.investing" },
    { label: "Real Estate", value: "business.realestate" },
    { label: "Digital Marketing", value: "business.marketing" },
    { label: "Freelancing & Side Hustles", value: "business.freelancing" },
    { label: "Career Advice", value: "business.career" },
  ],
  arts: [
    { label: "Digital Art & Design", value: "arts.digital" },
    { label: "Music Production", value: "arts.music" },
    { label: "Photography & Videography", value: "arts.photography" },
    { label: "Drawing & Painting", value: "arts.drawing" },
    { label: "Crafts & DIY", value: "arts.crafts" },
    { label: "Writing & Storytelling", value: "arts.writing" },
  ],
  travel: [
    { label: "Travel Vlogging", value: "travel.vlogging" },
    { label: "Budget Travel & Hacks", value: "travel.budget" },
    { label: "Food Tourism", value: "travel.food" },
    { label: "Adventure & Outdoor", value: "travel.adventure" },
    { label: "Digital Nomad Lifestyle", value: "travel.nomad" },
    { label: "Solo Travel", value: "travel.solo" },
  ],
  sports: [
    { label: "Fitness & Workouts", value: "sports.fitness" },
    { label: "Sports Commentary", value: "sports.commentary" },
    { label: "Extreme Sports", value: "sports.extreme" },
    { label: "Outdoor Recreation", value: "sports.outdoor" },
    { label: "Combat Sports & Martial Arts", value: "sports.combat" },
    { label: "Sports Highlights & Analysis", value: "sports.analysis" },
  ],
  kids: [
    { label: "Nursery Rhymes & Songs", value: "kids.nursery" },
    { label: "Educational Cartoons", value: "kids.educational" },
    { label: "Toys & Unboxing", value: "kids.toys" },
    { label: "Crafts & Activities", value: "kids.crafts" },
    { label: "Bedtime Stories", value: "kids.stories" },
    { label: "Family Vlogs", value: "kids.family" },
  ],
};

/**
 * Get subcategories for a given category value
 * @param categoryValue The value of the category to get subcategories for
 * @returns Array of subcategory options or empty array if category not found
 */
export function getSubcategories(categoryValue: string): Category[] {
  return subcategoryMap[categoryValue] || [];
}

/**
 * Format category and subcategory for display
 * @param category Main category value
 * @param subcategory Subcategory value (optional)
 * @returns Formatted string for display (e.g., "Education & Learning > Language Learning")
 */
export function formatTaxonomyPath(category: string, subcategory?: string): string {
  const categoryObj = categories.find(c => c.value === category);
  if (!categoryObj) return '';

  if (!subcategory) return categoryObj.label;

  const subcategoryObj = getSubcategories(category).find(s => s.value === subcategory);
  if (!subcategoryObj) return categoryObj.label;

  return `${categoryObj.label} > ${subcategoryObj.label}`;
}
EOL

# Create the NicheTaxonomySelector component
echo -e "${YELLOW}Creating NicheTaxonomySelector component...${NC}"
cat > "${MISSION_CONTROL}/src/components/workflows/NicheTaxonomySelector.tsx" << 'EOL'
import React, { useState } from 'react';
import { categories, getSubcategories } from '@/utils/shared-taxonomy';

interface NicheTaxonomySelectorProps {
  onSelect: (category: string, subcategory?: string) => void;
  onClose: () => void;
  step: number;
}

const NicheTaxonomySelector: React.FC<NicheTaxonomySelectorProps> = ({ onSelect, onClose, step }) => {
  const [selectedCategory, setSelectedCategory] = useState('');

  // Step indicator based on the current step
  const getStepClass = (stepNum: number) => {
    return step >= stepNum
      ? 'bg-blue-500 text-white'
      : 'bg-gray-200 text-gray-500';
  };

  // Handle category selection
  const handleCategorySelect = (categoryValue: string) => {
    setSelectedCategory(categoryValue);
    onSelect(categoryValue);
  };

  // Handle subcategory selection
  const handleSubcategorySelect = (subcategoryValue: string) => {
    onSelect(selectedCategory, subcategoryValue);
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-lg w-full">
        {/* Header with close button */}
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold">Select a Category</h2>
          <button
            onClick={onClose}
            className="text-gray-500 hover:text-gray-700"
            aria-label="Close"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path>
            </svg>
          </button>
        </div>

        {/* Step indicators */}
        <div className="flex justify-center mb-6">
          <div className="flex items-center">
            <div className={`rounded-full w-8 h-8 flex items-center justify-center ${getStepClass(1)}`}>1</div>
            <div className="w-8 h-1 bg-gray-200"></div>
            <div className={`rounded-full w-8 h-8 flex items-center justify-center ${getStepClass(2)}`}>2</div>
            <div className="w-8 h-1 bg-gray-200"></div>
            <div className={`rounded-full w-8 h-8 flex items-center justify-center ${getStepClass(3)}`}>3</div>
          </div>
        </div>

        {/* Instructions */}
        <p className="text-gray-600 dark:text-gray-300 mb-4">
          Choose the main category for your niche research
        </p>

        {/* Category selection */}
        {!selectedCategory && (
          <div className="grid grid-cols-1 gap-2 max-h-80 overflow-y-auto">
            {categories.map((category) => (
              <button
                key={category.value}
                onClick={() => handleCategorySelect(category.value)}
                className="text-left p-3 rounded-md bg-gray-50 dark:bg-gray-700 hover:bg-blue-50 dark:hover:bg-blue-900 border border-gray-200 dark:border-gray-600"
              >
                {category.label}
              </button>
            ))}
          </div>
        )}

        {/* Subcategory selection */}
        {selectedCategory && (
          <>
            <div className="flex items-center mb-4">
              <button
                onClick={() => setSelectedCategory('')}
                className="text-blue-500 hover:text-blue-700 flex items-center"
              >
                <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 19l-7-7 7-7"></path>
                </svg>
                Back to categories
              </button>
            </div>

            <h3 className="font-medium mb-3">
              {categories.find(c => c.value === selectedCategory)?.label}
            </h3>

            <div className="grid grid-cols-1 gap-2 max-h-80 overflow-y-auto">
              {getSubcategories(selectedCategory).map((subcategory) => (
                <button
                  key={subcategory.value}
                  onClick={() => handleSubcategorySelect(subcategory.value)}
                  className="text-left p-3 rounded-md bg-gray-50 dark:bg-gray-700 hover:bg-blue-50 dark:hover:bg-blue-900 border border-gray-200 dark:border-gray-600"
                >
                  {subcategory.label}
                </button>
              ))}
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default NicheTaxonomySelector;
EOL

# Install documentation
echo -e "${YELLOW}Installing documentation...${NC}"
mkdir -p "${PROJECT_ROOT}/docs"
cp "${PROJECT_ROOT}/docs/taxonomy-integration.md" "${PROJECT_ROOT}/docs/taxonomy-integration.md.backup" 2>/dev/null || true

echo -e "${GREEN}✅ Installation complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test in Mission Control: http://localhost:3007/workflows/niche-scout"
echo "2. Test in Agent Orchestrator: http://localhost:8080/agents/agent-1"
echo "3. Review documentation at: ${PROJECT_ROOT}/docs/taxonomy-integration.md"
