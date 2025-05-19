import React from 'react';
import { colors } from '../../../styles/design-tokens';

/**
 * Props for the GradientProgressBar component
 */
export interface GradientProgressBarProps {
  /** Current value (0-100) */
  value: number;
  /** Maximum value (default: 100) */
  max?: number;
  /** Color variant */
  variant?: 'primary' | 'secondary' | 'success' | 'warning' | 'error';
  /** Height of the progress bar */
  height?: number | string;
  /** Whether to show the value as text */
  showValue?: boolean;
  /** Format for the displayed value */
  valueFormat?: 'percentage' | 'raw' | 'custom';
  /** Custom formatter function for the value */
  valueFormatter?: (value: number, max: number) => string;
  /** Additional CSS classes */
  className?: string;
  /** Whether to animate the progress bar */
  animated?: boolean;
  /** Whether to use striped pattern */
  striped?: boolean;
  /** Optional label to display above the progress bar */
  label?: string;
}

/**
 * GradientProgressBar Component
 *
 * A progress bar with gradient styling
 *
 * @example
 * ```tsx
 * <GradientProgressBar
 *   value={75}
 *   variant="primary"
 *   showValue={true}
 *   animated={true}
 *   label="CPU Usage"
 * />
 * ```
 */
export const GradientProgressBar: React.FC<GradientProgressBarProps> = ({
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
    <div className={`w-full ${className}`}>
      {label && (
        <div className="flex justify-between mb-1">
          <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
            {label}
          </span>
          {showValue && (
            <span className="text-sm font-medium text-gray-700 dark:text-gray-300">
              {getFormattedValue()}
            </span>
          )}
        </div>
      )}

      <div
        className="w-full bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden"
        style={{ height }}
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
        />
      </div>

      {showValue && !label && (
        <div className="mt-1 text-sm text-gray-500 dark:text-gray-400 text-right">
          {getFormattedValue()}
        </div>
      )}
    </div>
  );
};

// Add keyframes for animated progress bars
const styleSheet = document.createElement('style');
styleSheet.textContent = `
  @keyframes progress-stripes {
    0% { background-position: 1rem 0; }
    100% { background-position: 0 0; }
  }

  .bg-stripes {
    background-image: linear-gradient(
      45deg,
      rgba(255, 255, 255, 0.15) 25%,
      transparent 25%,
      transparent 50%,
      rgba(255, 255, 255, 0.15) 50%,
      rgba(255, 255, 255, 0.15) 75%,
      transparent 75%,
      transparent
    );
    background-size: 1rem 1rem;
  }

  .animate-progress {
    animation: progress-stripes 1s linear infinite;
  }
`;
document.head.appendChild(styleSheet);

export default GradientProgressBar;
