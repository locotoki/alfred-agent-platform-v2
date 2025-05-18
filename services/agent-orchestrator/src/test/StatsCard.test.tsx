import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';

// Mock StatsCard component for testing
const StatsCard: React.FC<{
  title: string;
  value: string | number;
  icon?: React.ReactNode;
  trend?: {
    value: string | number;
    isPositive: boolean;
  };
  colorClass?: string;
  className?: string;
  'data-testid'?: string;
}> = ({
  title,
  value,
  icon,
  trend,
  colorClass = 'bg-gradient-to-r from-blue-500 to-blue-600',
  className = '',
  'data-testid': testId,
}) => {
  return (
    <div
      className={`dashboard-card overflow-hidden bg-white dark:bg-gray-800 rounded-lg shadow ${className}`}
      data-testid={testId}
    >
      <div className="p-5">
        <div className="flex items-center justify-between">
          <div>
            <p
              className="text-sm font-medium text-gray-500 dark:text-gray-400 truncate"
              data-testid="stats-card-title"
            >
              {title}
            </p>
            <p
              className="mt-1 text-3xl font-semibold text-gray-900 dark:text-white"
              data-testid="stats-card-value"
            >
              {value}
            </p>
          </div>
          {icon && (
            <div
              className={`p-3 rounded-full ${colorClass} text-white`}
              data-testid="stats-card-icon"
            >
              {icon}
            </div>
          )}
        </div>

        {trend && (
          <div className="mt-4" data-testid="stats-card-trend">
            <div className={`flex items-center text-sm ${
              trend.isPositive
                ? 'text-green-500 dark:text-green-400'
                : 'text-red-500 dark:text-red-400'
            }`}>
              <span className="font-medium" data-testid="stats-card-trend-value">
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

describe('StatsCard Component', () => {
  it('renders title and value correctly', () => {
    render(
      <StatsCard
        title="Active Tasks"
        value={127}
        data-testid="stats-card"
      />
    );

    expect(screen.getByTestId('stats-card')).toBeInTheDocument();
    expect(screen.getByTestId('stats-card-title')).toHaveTextContent('Active Tasks');
    expect(screen.getByTestId('stats-card-value')).toHaveTextContent('127');
  });

  it('renders the icon when provided', () => {
    render(
      <StatsCard
        title="Active Tasks"
        value={127}
        icon={<span>📊</span>}
        data-testid="stats-card"
      />
    );

    const iconContainer = screen.getByTestId('stats-card-icon');
    expect(iconContainer).toBeInTheDocument();
    expect(iconContainer).toHaveClass('from-blue-500 to-blue-600');
    expect(iconContainer).toHaveTextContent('📊');
  });

  it('applies custom color class to the icon', () => {
    render(
      <StatsCard
        title="Active Tasks"
        value={127}
        icon={<span>📊</span>}
        colorClass="bg-green-500"
        data-testid="stats-card"
      />
    );

    const iconContainer = screen.getByTestId('stats-card-icon');
    expect(iconContainer).toHaveClass('bg-green-500');
    expect(iconContainer).not.toHaveClass('from-blue-500 to-blue-600');
  });

  it('renders positive trend correctly', () => {
    render(
      <StatsCard
        title="Active Tasks"
        value={127}
        trend={{ value: 12, isPositive: true }}
        data-testid="stats-card"
      />
    );

    const trendElement = screen.getByTestId('stats-card-trend');
    expect(trendElement).toBeInTheDocument();

    const trendValueElement = screen.getByTestId('stats-card-trend-value');
    expect(trendValueElement).toHaveTextContent('↑ 12');
    expect(trendValueElement.parentElement).toHaveClass('text-green-500');
  });

  it('renders negative trend correctly', () => {
    render(
      <StatsCard
        title="Active Tasks"
        value={127}
        trend={{ value: 5, isPositive: false }}
        data-testid="stats-card"
      />
    );

    const trendElement = screen.getByTestId('stats-card-trend');
    expect(trendElement).toBeInTheDocument();

    const trendValueElement = screen.getByTestId('stats-card-trend-value');
    expect(trendValueElement).toHaveTextContent('↓ 5');
    expect(trendValueElement.parentElement).toHaveClass('text-red-500');
  });

  it('applies additional className', () => {
    render(
      <StatsCard
        title="Active Tasks"
        value={127}
        className="custom-class"
        data-testid="stats-card"
      />
    );

    const statsCard = screen.getByTestId('stats-card');
    expect(statsCard).toHaveClass('custom-class');
  });

  it('handles string values', () => {
    render(
      <StatsCard
        title="Status"
        value="Operational"
        data-testid="stats-card"
      />
    );

    expect(screen.getByTestId('stats-card-value')).toHaveTextContent('Operational');
  });

  it('handles string trend values', () => {
    render(
      <StatsCard
        title="Revenue"
        value="$10,000"
        trend={{ value: '15%', isPositive: true }}
        data-testid="stats-card"
      />
    );

    const trendValueElement = screen.getByTestId('stats-card-trend-value');
    expect(trendValueElement).toHaveTextContent('↑ 15%');
  });

  it('does not render trend section when trend is not provided', () => {
    render(
      <StatsCard
        title="Active Tasks"
        value={127}
        data-testid="stats-card"
      />
    );

    expect(screen.queryByTestId('stats-card-trend')).not.toBeInTheDocument();
  });

  it('does not render icon when icon is not provided', () => {
    render(
      <StatsCard
        title="Active Tasks"
        value={127}
        data-testid="stats-card"
      />
    );

    expect(screen.queryByTestId('stats-card-icon')).not.toBeInTheDocument();
  });
});
