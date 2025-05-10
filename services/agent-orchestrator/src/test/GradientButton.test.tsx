import React from 'react';
import { render, screen, fireEvent, act } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';

// Mock GradientButton component for testing
const GradientButton: React.FC<{
  children: React.ReactNode;
  onClick?: (event: React.MouseEvent<HTMLButtonElement>) => void;
  variant?: 'primary' | 'secondary' | 'success' | 'warning' | 'error';
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  disabled?: boolean;
  loading?: boolean;
  type?: 'button' | 'submit' | 'reset';
  className?: string;
  fullWidth?: boolean;
  iconBefore?: React.ReactNode;
  iconAfter?: React.ReactNode;
  'data-testid'?: string;
}> = ({
  children,
  onClick,
  variant = 'primary',
  size = 'md',
  disabled = false,
  loading = false,
  type = 'button',
  className = '',
  fullWidth = false,
  iconBefore,
  iconAfter,
  'data-testid': testId,
}) => {
  // Map size to appropriate padding and text size
  const sizeClasses = {
    xs: 'px-2.5 py-1.5 text-xs',
    sm: 'px-3 py-2 text-sm',
    md: 'px-4 py-2 text-sm',
    lg: 'px-4 py-2 text-base',
    xl: 'px-6 py-3 text-base',
  };
  
  // Get gradient colors based on variant
  const getGradientColors = () => {
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
  
  // Get the background based on state
  const getBackground = () => {
    if (disabled) return 'bg-gray-300 dark:bg-gray-700';
    return `bg-gradient-to-r ${getGradientColors()}`;
  };

  return (
    <button
      type={type}
      className={`
        ${getBackground()}
        ${sizeClasses[size]}
        ${fullWidth ? 'w-full' : ''}
        rounded-md
        font-medium
        text-white
        shadow-sm
        transition-all
        duration-200
        ${!disabled && 'hover:shadow-md hover:transform hover:-translate-y-0.5'}
        ${disabled ? 'cursor-not-allowed opacity-60' : 'cursor-pointer'}
        ${className}
      `}
      onClick={onClick}
      disabled={disabled || loading}
      data-testid={testId}
    >
      <div className="flex items-center justify-center">
        {loading && (
          <svg 
            className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" 
            xmlns="http://www.w3.org/2000/svg" 
            fill="none" 
            viewBox="0 0 24 24"
            data-testid="loading-spinner"
          >
            <circle 
              className="opacity-25" 
              cx="12" 
              cy="12" 
              r="10" 
              stroke="currentColor" 
              strokeWidth="4"
            ></circle>
            <path 
              className="opacity-75" 
              fill="currentColor" 
              d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
            ></path>
          </svg>
        )}
        
        {iconBefore && !loading && (
          <span className="mr-2" data-testid="icon-before">{iconBefore}</span>
        )}
        
        {children}
        
        {iconAfter && (
          <span className="ml-2" data-testid="icon-after">{iconAfter}</span>
        )}
      </div>
    </button>
  );
};

describe('GradientButton Component', () => {
  it('renders children correctly', () => {
    render(
      <GradientButton data-testid="test-button">Click Me</GradientButton>
    );
    
    expect(screen.getByTestId('test-button')).toBeInTheDocument();
    expect(screen.getByText('Click Me')).toBeInTheDocument();
  });

  it('calls onClick handler when clicked', () => {
    const handleClick = vi.fn();
    
    render(
      <GradientButton onClick={handleClick} data-testid="test-button">Click Me</GradientButton>
    );
    
    fireEvent.click(screen.getByTestId('test-button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('does not call onClick when disabled', () => {
    const handleClick = vi.fn();
    
    render(
      <GradientButton onClick={handleClick} disabled data-testid="test-button">Click Me</GradientButton>
    );
    
    fireEvent.click(screen.getByTestId('test-button'));
    expect(handleClick).not.toHaveBeenCalled();
  });

  it('renders with different size variants', () => {
    const { rerender } = render(
      <GradientButton size="xs" data-testid="test-button">Click Me</GradientButton>
    );
    
    expect(screen.getByTestId('test-button')).toHaveClass('px-2.5 py-1.5 text-xs');
    
    rerender(
      <GradientButton size="sm" data-testid="test-button">Click Me</GradientButton>
    );
    expect(screen.getByTestId('test-button')).toHaveClass('px-3 py-2 text-sm');
    
    rerender(
      <GradientButton size="md" data-testid="test-button">Click Me</GradientButton>
    );
    expect(screen.getByTestId('test-button')).toHaveClass('px-4 py-2 text-sm');
    
    rerender(
      <GradientButton size="lg" data-testid="test-button">Click Me</GradientButton>
    );
    expect(screen.getByTestId('test-button')).toHaveClass('px-4 py-2 text-base');
    
    rerender(
      <GradientButton size="xl" data-testid="test-button">Click Me</GradientButton>
    );
    expect(screen.getByTestId('test-button')).toHaveClass('px-6 py-3 text-base');
  });

  it('applies correct gradients for different variants', () => {
    const { rerender } = render(
      <GradientButton variant="primary" data-testid="test-button">Click Me</GradientButton>
    );
    
    expect(screen.getByTestId('test-button')).toHaveClass('from-blue-500 to-blue-600');
    
    rerender(
      <GradientButton variant="secondary" data-testid="test-button">Click Me</GradientButton>
    );
    expect(screen.getByTestId('test-button')).toHaveClass('from-purple-500 to-purple-600');
    
    rerender(
      <GradientButton variant="success" data-testid="test-button">Click Me</GradientButton>
    );
    expect(screen.getByTestId('test-button')).toHaveClass('from-green-500 to-green-600');
    
    rerender(
      <GradientButton variant="warning" data-testid="test-button">Click Me</GradientButton>
    );
    expect(screen.getByTestId('test-button')).toHaveClass('from-yellow-500 to-yellow-600');
    
    rerender(
      <GradientButton variant="error" data-testid="test-button">Click Me</GradientButton>
    );
    expect(screen.getByTestId('test-button')).toHaveClass('from-red-500 to-red-600');
  });

  it('applies disabled styling when disabled', () => {
    render(
      <GradientButton disabled data-testid="test-button">Click Me</GradientButton>
    );
    
    const button = screen.getByTestId('test-button');
    expect(button).toHaveClass('cursor-not-allowed opacity-60');
    expect(button).toHaveClass('bg-gray-300 dark:bg-gray-700');
    expect(button).toBeDisabled();
  });

  it('shows loading indicator when loading', () => {
    render(
      <GradientButton loading data-testid="test-button">Click Me</GradientButton>
    );
    
    expect(screen.getByTestId('test-button')).toBeDisabled();
    expect(screen.getByText('Click Me')).toBeInTheDocument();
    expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
  });

  it('applies fullWidth styling when requested', () => {
    render(
      <GradientButton fullWidth data-testid="test-button">Click Me</GradientButton>
    );
    
    expect(screen.getByTestId('test-button')).toHaveClass('w-full');
  });

  it('renders iconBefore correctly', () => {
    render(
      <GradientButton 
        iconBefore={<span>👈</span>} 
        data-testid="test-button"
      >
        Click Me
      </GradientButton>
    );
    
    expect(screen.getByTestId('icon-before')).toBeInTheDocument();
    expect(screen.getByTestId('icon-before')).toHaveClass('mr-2');
  });

  it('renders iconAfter correctly', () => {
    render(
      <GradientButton 
        iconAfter={<span>👉</span>} 
        data-testid="test-button"
      >
        Click Me
      </GradientButton>
    );
    
    expect(screen.getByTestId('icon-after')).toBeInTheDocument();
    expect(screen.getByTestId('icon-after')).toHaveClass('ml-2');
  });

  it('hides iconBefore when loading', () => {
    render(
      <GradientButton 
        iconBefore={<span>👈</span>} 
        loading
        data-testid="test-button"
      >
        Click Me
      </GradientButton>
    );
    
    expect(screen.queryByTestId('icon-before')).not.toBeInTheDocument();
    expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
  });

  it('applies custom className', () => {
    render(
      <GradientButton className="custom-class" data-testid="test-button">Click Me</GradientButton>
    );
    
    expect(screen.getByTestId('test-button')).toHaveClass('custom-class');
  });

  it('sets the button type correctly', () => {
    const { rerender } = render(
      <GradientButton type="button" data-testid="test-button">Click Me</GradientButton>
    );
    
    expect(screen.getByTestId('test-button')).toHaveAttribute('type', 'button');
    
    rerender(
      <GradientButton type="submit" data-testid="test-button">Click Me</GradientButton>
    );
    expect(screen.getByTestId('test-button')).toHaveAttribute('type', 'submit');
    
    rerender(
      <GradientButton type="reset" data-testid="test-button">Click Me</GradientButton>
    );
    expect(screen.getByTestId('test-button')).toHaveAttribute('type', 'reset');
  });
});