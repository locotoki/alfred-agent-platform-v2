import React from 'react';
import { IconType } from 'react-icons';

interface StatsCardProps {
  title: string;
  value: string | number;
  icon?: IconType;
  trend?: {
    value: string | number;
    isPositive: boolean;
  };
  colorClass?: string;
}

const StatsCard: React.FC<StatsCardProps> = ({
  title,
  value,
  icon: Icon,
  trend,
  colorClass = 'bg-blue-500'
}) => {
  return (
    <div className="dashboard-card overflow-hidden bg-white dark:bg-gray-800 rounded-lg shadow">
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
          {Icon && (
            <div className={`p-3 rounded-full ${colorClass} text-white`}>
              <Icon className="h-6 w-6" />
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
