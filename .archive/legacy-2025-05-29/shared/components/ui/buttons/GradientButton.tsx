import React from 'react';
import { colors, typography, borders, animations } from '../../../../styles/design-tokens';

/**
 * Props for the GradientButton component
 */
export interface GradientButtonProps {
  /** Button content */
  children: React.ReactNode;
  /** Button click handler */
  onClick?: (event: React.MouseEvent<HTMLButtonElement>) => void;
  /** Color variant */
  variant?: 'primary' | 'secondary' | 'success' | 'warning' | 'error';
  /** Button size */
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  /** Whether the button is disabled */
  disabled?: boolean;
  /** Whether the button is in loading state */
  loading?: boolean;
  /** Button type */
  type?: 'button' | 'submit' | 'reset';
  /** Additional CSS classes */
  className?: string;
  /** Whether to use full width */
  fullWidth?: boolean;
  /** Optional icon to display before the text */
  iconBefore?: React.ReactNode;
  /** Optional icon to display after the text */
  iconAfter?: React.ReactNode;
}

/**
 * GradientButton Component
 *
 * A button component with gradient styling
 *
 * @example
 * ```tsx
 * <GradientButton
 *   variant="primary"
 *   size="md"
 *   onClick={() => console.log('Button clicked')}
 * >
 *   Click Me
 * </GradientButton>
 * ```
 */
export const GradientButton: React.FC<GradientButtonProps> = ({
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
}) => {
  // Map size to appropriate padding and text size
  const sizeClasses = {
    xs: 'px-2.5 py-1.5 text-xs',
    sm: 'px-3 py-2 text-sm',
    md: 'px-4 py-2 text-sm',
    lg: 'px-4 py-2 text-base',
    xl: 'px-6 py-3 text-base',
  };

  // Get the gradient based on variant
  const getBackground = () => {
    if (disabled) return 'bg-gray-300 dark:bg-gray-700';
    return `bg-gradient-to-r ${getGradientColors()}`;
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
        focus:outline-none
        focus:ring-2
        focus:ring-offset-2
        focus:ring-${variant}-500
        ${!disabled && 'hover:shadow-md hover:transform hover:-translate-y-0.5'}
        ${disabled ? 'cursor-not-allowed opacity-60' : 'cursor-pointer'}
        ${className}
      `}
      onClick={onClick}
      disabled={disabled || loading}
    >
      <div className="flex items-center justify-center">
        {loading && (
          <svg
            className="animate-spin -ml-1 mr-2 h-4 w-4 text-white"
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
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
          <span className="mr-2">{iconBefore}</span>
        )}

        {children}

        {iconAfter && (
          <span className="ml-2">{iconAfter}</span>
        )}
      </div>
    </button>
  );
};

export default GradientButton;
