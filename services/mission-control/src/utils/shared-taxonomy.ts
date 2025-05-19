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

// Categories that match the UI dropdown exactly
export const categories: Category[] = [
  { label: "All", value: "all" },
  { label: "Gaming", value: "gaming" },
  { label: "Education", value: "education" },
  { label: "Entertainment", value: "entertainment" },
  { label: "Howto & Style", value: "howto" },
  { label: "Science & Technology", value: "science" }
];

// Subcategories matching what's in the current implementation
export const subcategoryMap: Record<string, Category[]> = {
  gaming: [
    { label: "FPS Games", value: "gaming.fps" },
    { label: "RPG Games", value: "gaming.rpg" },
    { label: "Strategy Games", value: "gaming.strategy" },
    { label: "Mobile Gaming", value: "gaming.mobile" },
    { label: "Game Reviews", value: "gaming.reviews" }
  ],
  education: [
    { label: "Language Learning", value: "education.language" },
    { label: "Exam Prep", value: "education.exams" },
    { label: "STEM Tutorials", value: "education.stem" },
    { label: "DIY", value: "education.diy" },
    { label: "Science", value: "education.science" }
  ],
  entertainment: [
    { label: "Comedy", value: "entertainment.comedy" },
    { label: "Vlogs", value: "entertainment.vlogs" },
    { label: "Reactions", value: "entertainment.reactions" },
    { label: "Shorts", value: "entertainment.shorts" },
    { label: "Storytelling", value: "entertainment.storytelling" }
  ],
  howto: [
    { label: "Beauty", value: "howto.beauty" },
    { label: "Fashion", value: "howto.fashion" },
    { label: "Home Decor", value: "howto.decor" },
    { label: "Cooking", value: "howto.cooking" },
    { label: "Crafts", value: "howto.crafts" }
  ],
  science: [
    { label: "Gadget Reviews", value: "science.gadgets" },
    { label: "Coding", value: "science.coding" },
    { label: "AI & ML", value: "science.ai" },
    { label: "Engineering", value: "science.engineering" },
    { label: "Science News", value: "science.news" }
  ]
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
 * @returns Formatted string for display (e.g., "Education > Language Learning")
 */
export function formatTaxonomyPath(category: string, subcategory?: string): string {
  if (category === "all") return "All";

  const categoryObj = categories.find(c => c.value === category);
  if (!categoryObj) return '';

  if (!subcategory) return categoryObj.label;

  const subcategoryObj = getSubcategories(category).find(s => s.value === subcategory);
  if (!subcategoryObj) return categoryObj.label;

  return `${categoryObj.label} > ${subcategoryObj.label}`;
}
