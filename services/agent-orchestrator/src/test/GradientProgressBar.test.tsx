import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';

// Mock GradientProgressBar component for testing
const GradientProgressBar: React.FC<{
  value: number;
  max?: number;
  variant?: 'primary' | 'secondary' | 'success' | 'warning' | 'error';
  height?: number | string;
  showValue?: boolean;
  valueFormat?: 'percentage' | 'raw' | 'custom';
  valueFormatter?: (value: number, max: number) => string;
  className?: string;
  animated?: boolean;
  striped?: boolean;
  label?: string;
  'data-testid'?: string;
}> = ({
  value,
  max = 100,
  variant = 'primary',
  height = '0.5rem',
  showValue = false,
  valueFormat = 'percentage',
  valueFormatter,
  className = '',
  animated = false,
  striped = false,
  label,
  'data-testid': testId,
}) => {
  // Ensure value is between 0 and max
  const normalizedValue = Math.min(Math.max(0, value), max);
  const percentage = (normalizedValue / max) * 100;
  
  // Get gradient based on variant
  const getGradient = () => {
    switch (variant) {
      case 'primary':
        return 'from-blue-500 to-blue-600';
      case 'secondary':
        return 'from-purple-500 to-purple-600';
      case 'success':
        return 'from-green-500 to-green-600';
      case 'warning':
        return 'from-yellow-500 to-yellow-600';
      case 'error':
        return 'from-red-500 to-red-600';
      default:
        return 'from-blue-500 to-blue-600';
    }
  };
  
  // Format the displayed value
  const getFormattedValue = () => {
    if (valueFormatter) {
      return valueFormatter(normalizedValue, max);
    }
    
    switch (valueFormat) {
      case 'percentage':
        return `${Math.round(percentage)}%`;
      case 'raw':
        return `${normalizedValue}/${max}`;
      default:
        return `${Math.round(percentage)}%`;
    }
  };
  
  return (
    <div className={`w-full ${className}`} data-testid={testId}>
      {label && (
        <div className="flex justify-between mb-1" data-testid="progress-label-container">
          <span className="text-sm font-medium text-gray-700 dark:text-gray-300" data-testid="progress-label">
            {label}
          </span>
          {showValue && (
            <span className="text-sm font-medium text-gray-700 dark:text-gray-300" data-testid="progress-value-with-label">
              {getFormattedValue()}
            </span>
          )}
        </div>
      )}
      
      <div 
        className="w-full bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden"
        style={{ height }}
        data-testid="progress-track"
      >
        <div
          className={`
            bg-gradient-to-r ${getGradient()}
            ${striped ? 'bg-stripes' : ''}
            ${animated ? 'animate-progress' : ''}
            rounded-full
          `}
          style={{ 
            width: `${percentage}%`,
            height: '100%',
            transition: 'width 0.5s ease-in-out'
          }}
          data-testid="progress-bar"
        />
      </div>
      
      {showValue && !label && (
        <div className="mt-1 text-sm text-gray-500 dark:text-gray-400 text-right" data-testid="progress-value-no-label">
          {getFormattedValue()}
        </div>
      )}
    </div>
  );
};

describe('GradientProgressBar Component', () => {
  it('renders correctly with default props', () => {
    render(<GradientProgressBar value={50} data-testid="progress" />);
    
    expect(screen.getByTestId('progress')).toBeInTheDocument();
    expect(screen.getByTestId('progress-track')).toBeInTheDocument();
    
    const progressBar = screen.getByTestId('progress-bar');
    expect(progressBar).toHaveStyle('width: 50%');
    expect(progressBar).toHaveClass('from-blue-500 to-blue-600');
  });

  it('clamps value between 0 and max', () => {
    const { rerender } = render(<GradientProgressBar value={-10} data-testid="progress" />);
    
    let progressBar = screen.getByTestId('progress-bar');
    expect(progressBar).toHaveStyle('width: 0%');
    
    rerender(<GradientProgressBar value={150} max={100} data-testid="progress" />);
    progressBar = screen.getByTestId('progress-bar');
    expect(progressBar).toHaveStyle('width: 100%');
  });

  it('applies correct gradient based on variant', () => {
    const { rerender } = render(<GradientProgressBar value={50} variant="primary" data-testid="progress" />);
    
    let progressBar = screen.getByTestId('progress-bar');
    expect(progressBar).toHaveClass('from-blue-500 to-blue-600');
    
    rerender(<GradientProgressBar value={50} variant="secondary" data-testid="progress" />);
    progressBar = screen.getByTestId('progress-bar');
    expect(progressBar).toHaveClass('from-purple-500 to-purple-600');
    
    rerender(<GradientProgressBar value={50} variant="success" data-testid="progress" />);
    progressBar = screen.getByTestId('progress-bar');
    expect(progressBar).toHaveClass('from-green-500 to-green-600');
    
    rerender(<GradientProgressBar value={50} variant="warning" data-testid="progress" />);
    progressBar = screen.getByTestId('progress-bar');
    expect(progressBar).toHaveClass('from-yellow-500 to-yellow-600');
    
    rerender(<GradientProgressBar value={50} variant="error" data-testid="progress" />);
    progressBar = screen.getByTestId('progress-bar');
    expect(progressBar).toHaveClass('from-red-500 to-red-600');
  });

  it('renders with custom height', () => {
    render(<GradientProgressBar value={50} height="16px" data-testid="progress" />);

    const progressTrack = screen.getByTestId('progress-track');
    expect(progressTrack).toHaveStyle('height: 16px');
  });

  it('displays label when provided', () => {
    render(<GradientProgressBar value={50} label="CPU Usage" data-testid="progress" />);
    
    expect(screen.getByTestId('progress-label')).toBeInTheDocument();
    expect(screen.getByText('CPU Usage')).toBeInTheDocument();
  });

  it('shows value with different formats', () => {
    const { rerender } = render(
      <GradientProgressBar 
        value={50} 
        max={100} 
        showValue={true} 
        valueFormat="percentage" 
        data-testid="progress" 
      />
    );
    
    expect(screen.getByTestId('progress-value-no-label')).toBeInTheDocument();
    expect(screen.getByText('50%')).toBeInTheDocument();
    
    rerender(
      <GradientProgressBar 
        value={50} 
        max={100} 
        showValue={true} 
        valueFormat="raw" 
        data-testid="progress" 
      />
    );
    
    expect(screen.getByText('50/100')).toBeInTheDocument();
  });

  it('shows value along with label when both are provided', () => {
    render(
      <GradientProgressBar 
        value={75} 
        label="Memory" 
        showValue={true} 
        data-testid="progress" 
      />
    );
    
    expect(screen.getByTestId('progress-label')).toBeInTheDocument();
    expect(screen.getByTestId('progress-value-with-label')).toBeInTheDocument();
    expect(screen.getByText('Memory')).toBeInTheDocument();
    expect(screen.getByText('75%')).toBeInTheDocument();
  });

  it('uses custom value formatter when provided', () => {
    const customFormatter = vi.fn().mockReturnValue('Custom Value');
    
    render(
      <GradientProgressBar 
        value={50} 
        max={100} 
        showValue={true} 
        valueFormatter={customFormatter} 
        data-testid="progress" 
      />
    );
    
    expect(customFormatter).toHaveBeenCalledWith(50, 100);
    expect(screen.getByText('Custom Value')).toBeInTheDocument();
  });

  it('applies animation and striped classes when requested', () => {
    const { rerender } = render(
      <GradientProgressBar 
        value={50} 
        animated={true} 
        data-testid="progress" 
      />
    );
    
    let progressBar = screen.getByTestId('progress-bar');
    expect(progressBar).toHaveClass('animate-progress');
    expect(progressBar).not.toHaveClass('bg-stripes');
    
    rerender(
      <GradientProgressBar 
        value={50} 
        striped={true} 
        data-testid="progress" 
      />
    );
    
    progressBar = screen.getByTestId('progress-bar');
    expect(progressBar).toHaveClass('bg-stripes');
    expect(progressBar).not.toHaveClass('animate-progress');
    
    rerender(
      <GradientProgressBar 
        value={50} 
        animated={true} 
        striped={true} 
        data-testid="progress" 
      />
    );
    
    progressBar = screen.getByTestId('progress-bar');
    expect(progressBar).toHaveClass('animate-progress');
    expect(progressBar).toHaveClass('bg-stripes');
  });

  it('applies additional className', () => {
    render(
      <GradientProgressBar 
        value={50} 
        className="custom-class" 
        data-testid="progress" 
      />
    );
    
    const container = screen.getByTestId('progress');
    expect(container).toHaveClass('custom-class');
  });
});