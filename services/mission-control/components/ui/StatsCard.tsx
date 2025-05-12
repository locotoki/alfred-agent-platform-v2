import React, { ReactNode } from 'react';
import { 
  FiArrowUp, 
  FiArrowDown, 
  FiActivity, 
  FiUser, 
  FiCpu, 
  FiTrendingUp 
} from 'react-icons/fi';

interface StatsCardProps {
  title: string;
  value: string | number;
  change?: number;
  trend?: 'up' | 'down' | 'neutral';
  prefix?: string;
  suffix?: string;
  icon?: ReactNode;
  onClick?: () => void;
}

export default function StatsCard({
  title,
  value,
  change,
  trend = 'neutral',
  prefix,
  suffix,
  icon,
  onClick
}: StatsCardProps) {
  const defaultIcons = {
    activity: <FiActivity className="h-6 w-6 text-primary-500" />,
    user: <FiUser className="h-6 w-6 text-primary-500" />,
    cpu: <FiCpu className="h-6 w-6 text-primary-500" />,
    trending: <FiTrendingUp className="h-6 w-6 text-primary-500" />
  };

  const renderIcon = () => {
    if (icon) return icon;
    return defaultIcons.activity;
  };

  return (
    <div 
      className={`stat-card ${onClick ? 'cursor-pointer' : ''}`}
      onClick={onClick}
    >
      <div className="flex justify-between items-start">
        <span className="stat-label">{title}</span>
        {renderIcon()}
      </div>
      
      <div className="stat-value">
        {prefix}{value}{suffix}
      </div>
      
      {change !== undefined && (
        <div className={trend === 'up' ? 'stat-trend-up' : trend === 'down' ? 'stat-trend-down' : 'text-gray-500 dark:text-gray-400'}>
          {trend === 'up' ? (
            <FiArrowUp className="mr-1" />
          ) : trend === 'down' ? (
            <FiArrowDown className="mr-1" />
          ) : null}
          
          {trend === 'up' ? '+' : ''}{change}%
        </div>
      )}
    </div>
  );
}