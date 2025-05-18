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
