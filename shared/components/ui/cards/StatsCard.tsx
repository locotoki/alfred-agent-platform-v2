import React from 'react';
import { colors, typography, borders, shadows } from '../../../../styles/design-tokens';

/**
 * Props for the StatsCard component
 */
export interface StatsCardProps {
  /** Title of the card */
  title: string;
  /** Value to display */
  value: string | number;
  /** Optional icon component */
  icon?: React.ReactNode;
  /** Optional trend information */
  trend?: {
    /** Value of the trend (can be number or percentage) */
    value: string | number;
    /** Whether the trend is positive */
    isPositive: boolean;
  };
  /** Color class for the icon background */
  colorClass?: string;
  /** Additional CSS classes */
  className?: string;
}

/**
 * StatsCard Component
 * 
 * Displays a statistic with optional icon and trend information
 * 
 * @example
 * ```tsx
 * <StatsCard 
 *   title="Active Tasks" 
 *   value={127} 
 *   icon={<TaskIcon />}
 *   trend={{ value: 12, isPositive: true }}
 *   colorClass="bg-blue-500"
 * />
 * ```
 */
export const StatsCard: React.FC<StatsCardProps> = ({
  title,
  value,
  icon,
  trend,
  colorClass = 'bg-gradient-to-r from-blue-500 to-blue-600',
  className = '',
}) => {
  return (
    <div className={`dashboard-card overflow-hidden bg-white dark:bg-gray-800 rounded-lg shadow ${className}`}>
      <div className="p-5">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-gray-500 dark:text-gray-400 truncate">
              {title}
            </p>
            <p className="mt-1 text-3xl font-semibold text-gray-900 dark:text-white">
              {value}
            </p>
          </div>
          {icon && (
            <div className={`p-3 rounded-full ${colorClass} text-white`}>
              {icon}
            </div>
          )}
        </div>
        
        {trend && (
          <div className="mt-4">
            <div className={`flex items-center text-sm ${
              trend.isPositive 
                ? 'text-green-500 dark:text-green-400' 
                : 'text-red-500 dark:text-red-400'
            }`}>
              <span className="font-medium">
                {trend.isPositive ? '↑' : '↓'} {trend.value}
              </span>
              <span className="ml-2 text-gray-500 dark:text-gray-400">from previous period</span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default StatsCard;