import React, { useState, useRef, useEffect } from 'react';
import { categories } from '../../utils/shared-taxonomy';

interface CategoryDropdownProps {
  value: string;
  onChange: (value: string) => void;
}

const CategoryDropdown: React.FC<CategoryDropdownProps> = ({ value, onChange }) => {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Get display label for the selected value
  const getSelectedLabel = (): string => {
    if (!value) return 'All';
    const category = categories.find(c => c.value === value);
    return category ? category.label : 'All';
  };

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  return (
    <div className="relative w-full" ref={dropdownRef}>
      {/* Dropdown trigger button */}
      <button
        type="button"
        className="w-full px-4 py-2 text-left bg-white border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
        onClick={() => setIsOpen(!isOpen)}
        aria-haspopup="listbox"
        aria-expanded={isOpen}
      >
        <div className="flex items-center justify-between">
          <span>{getSelectedLabel()}</span>
          <svg
            className="w-5 h-5 ml-2 -mr-1 text-gray-400"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
          >
            <path
              fillRule="evenodd"
              d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
              clipRule="evenodd"
            />
          </svg>
        </div>
      </button>

      {/* Dropdown menu */}
      {isOpen && (
        <div
          className="absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-md shadow-lg max-h-60 overflow-auto"
          role="listbox"
        >
          <ul className="py-1">
            {categories.map((category) => (
              <li
                key={category.value}
                className={`px-4 py-2 text-sm cursor-pointer hover:bg-blue-100 ${
                  value === category.value ? 'bg-blue-500 text-white' : 'text-gray-900'
                }`}
                onClick={() => {
                  onChange(category.value);
                  setIsOpen(false);
                }}
                role="option"
                aria-selected={value === category.value}
              >
                {category.label}
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};

export default CategoryDropdown;
