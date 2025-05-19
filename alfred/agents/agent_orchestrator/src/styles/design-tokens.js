/**
 * Design Tokens System
 *
 * This file defines the core design tokens for the Alfred Agent Platform UI.
 * These tokens should be used across the application to ensure visual consistency.
 */

export const colors = {
  // Primary color with gradients
  primary: {
    50: '#eff6ff',
    100: '#dbeafe',
    200: '#bfdbfe',
    300: '#93c5fd',
    400: '#60a5fa',
    500: '#3b82f6',
    600: '#2563eb',
    700: '#1d4ed8',
    800: '#1e40af',
    900: '#1e3a8a',
    950: '#172554',
    // Gradients
    gradient: 'linear-gradient(to right, #3b82f6, #2563eb)',
    gradientHover: 'linear-gradient(to right, #60a5fa, #3b82f6)',
    gradientActive: 'linear-gradient(to right, #2563eb, #1d4ed8)',
  },

  // Secondary color with gradients
  secondary: {
    50: '#f5f3ff',
    100: '#ede9fe',
    200: '#ddd6fe',
    300: '#c4b5fd',
    400: '#a78bfa',
    500: '#8b5cf6',
    600: '#7c3aed',
    700: '#6d28d9',
    800: '#5b21b6',
    900: '#4c1d95',
    950: '#2e1065',
    // Gradients
    gradient: 'linear-gradient(to right, #8b5cf6, #6d28d9)',
    gradientHover: 'linear-gradient(to right, #a78bfa, #8b5cf6)',
    gradientActive: 'linear-gradient(to right, #6d28d9, #5b21b6)',
  },

  // Success colors
  success: {
    50: '#ecfdf5',
    100: '#d1fae5',
    200: '#a7f3d0',
    300: '#6ee7b7',
    400: '#34d399',
    500: '#10b981',
    600: '#059669',
    700: '#047857',
    800: '#065f46',
    900: '#064e3b',
    950: '#022c22',
    // Gradients
    gradient: 'linear-gradient(to right, #10b981, #059669)',
  },

  // Warning colors
  warning: {
    50: '#fffbeb',
    100: '#fef3c7',
    200: '#fde68a',
    300: '#fcd34d',
    400: '#fbbf24',
    500: '#f59e0b',
    600: '#d97706',
    700: '#b45309',
    800: '#92400e',
    900: '#78350f',
    950: '#451a03',
    // Gradients
    gradient: 'linear-gradient(to right, #f59e0b, #d97706)',
  },

  // Error colors
  error: {
    50: '#fef2f2',
    100: '#fee2e2',
    200: '#fecaca',
    300: '#fca5a5',
    400: '#f87171',
    500: '#ef4444',
    600: '#dc2626',
    700: '#b91c1c',
    800: '#991b1b',
    900: '#7f1d1d',
    950: '#450a0a',
    // Gradients
    gradient: 'linear-gradient(to right, #ef4444, #dc2626)',
  },

  // Neutral colors
  neutral: {
    50: '#f9fafb',
    100: '#f3f4f6',
    200: '#e5e7eb',
    300: '#d1d5db',
    400: '#9ca3af',
    500: '#6b7280',
    600: '#4b5563',
    700: '#374151',
    800: '#1f2937',
    900: '#111827',
    950: '#030712',
  },

  // Dark mode colors
  dark: {
    background: '#111827',
    card: '#1f2937',
    border: '#374151',
    text: '#f9fafb',
  }
};

export const spacing = {
  'px': '1px',
  '0': '0',
  '0.5': '0.125rem',
  '1': '0.25rem',
  '1.5': '0.375rem',
  '2': '0.5rem',
  '2.5': '0.625rem',
  '3': '0.75rem',
  '3.5': '0.875rem',
  '4': '1rem',
  '5': '1.25rem',
  '6': '1.5rem',
  '7': '1.75rem',
  '8': '2rem',
  '9': '2.25rem',
  '10': '2.5rem',
  '11': '2.75rem',
  '12': '3rem',
  '14': '3.5rem',
  '16': '4rem',
  '20': '5rem',
  '24': '6rem',
  '28': '7rem',
  '32': '8rem',
  '36': '9rem',
  '40': '10rem',
  '44': '11rem',
  '48': '12rem',
  '52': '13rem',
  '56': '14rem',
  '60': '15rem',
  '64': '16rem',
  '72': '18rem',
  '80': '20rem',
  '96': '24rem',
};

export const typography = {
  // Font families
  fontFamily: {
    sans: 'ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif',
    serif: 'ui-serif, Georgia, Cambria, "Times New Roman", Times, serif',
    mono: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace',
  },

  // Font sizes
  fontSize: {
    'xs': '0.75rem',    // 12px
    'sm': '0.875rem',   // 14px
    'base': '1rem',     // 16px
    'lg': '1.125rem',   // 18px
    'xl': '1.25rem',    // 20px
    '2xl': '1.5rem',    // 24px
    '3xl': '1.875rem',  // 30px
    '4xl': '2.25rem',   // 36px
    '5xl': '3rem',      // 48px
    '6xl': '3.75rem',   // 60px
    '7xl': '4.5rem',    // 72px
    '8xl': '6rem',      // 96px
    '9xl': '8rem',      // 128px
  },

  // Font weights
  fontWeight: {
    thin: '100',
    extralight: '200',
    light: '300',
    normal: '400',
    medium: '500',
    semibold: '600',
    bold: '700',
    extrabold: '800',
    black: '900',
  },

  // Line heights
  lineHeight: {
    none: '1',
    tight: '1.25',
    snug: '1.375',
    normal: '1.5',
    relaxed: '1.625',
    loose: '2',
    '3': '.75rem',
    '4': '1rem',
    '5': '1.25rem',
    '6': '1.5rem',
    '7': '1.75rem',
    '8': '2rem',
    '9': '2.25rem',
    '10': '2.5rem',
  },
};

export const borders = {
  borderRadius: {
    'none': '0',
    'sm': '0.125rem',   // 2px
    'md': '0.25rem',    // 4px
    'lg': '0.375rem',   // 6px
    'xl': '0.5rem',     // 8px
    '2xl': '0.75rem',   // 12px
    '3xl': '1rem',      // 16px
    'full': '9999px',
  },

  borderWidth: {
    '0': '0',
    '1': '1px',
    '2': '2px',
    '4': '4px',
    '8': '8px',
  },
};

export const shadows = {
  'none': 'none',
  'sm': '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
  'md': '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
  'lg': '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
  'xl': '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
  '2xl': '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
  'inner': 'inset 0 2px 4px 0 rgba(0, 0, 0, 0.06)',
};

export const animations = {
  transition: {
    'none': 'none',
    'all': 'all 0.3s ease',
    'colors': 'colors 0.3s ease',
    'opacity': 'opacity 0.3s ease',
    'shadow': 'box-shadow 0.3s ease',
    'transform': 'transform 0.3s ease',
  },

  keyframes: {
    spin: {
      from: { transform: 'rotate(0deg)' },
      to: { transform: 'rotate(360deg)' },
    },
    ping: {
      '0%': { transform: 'scale(1)', opacity: '1' },
      '75%, 100%': { transform: 'scale(2)', opacity: '0' },
    },
    pulse: {
      '0%, 100%': { opacity: '1' },
      '50%': { opacity: '.5' },
    },
    bounce: {
      '0%, 100%': {
        transform: 'translateY(0)',
        animationTimingFunction: 'cubic-bezier(0.8, 0, 1, 1)',
      },
      '50%': {
        transform: 'translateY(-25%)',
        animationTimingFunction: 'cubic-bezier(0, 0, 0.2, 1)',
      },
    },
  },

  animation: {
    'none': 'none',
    'spin': 'spin 1s linear infinite',
    'ping': 'ping 1s cubic-bezier(0, 0, 0.2, 1) infinite',
    'pulse': 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
    'bounce': 'bounce 1s infinite',
  },
};

// Z-index values
export const zIndex = {
  '0': '0',
  '10': '10',
  '20': '20',
  '30': '30',
  '40': '40',
  '50': '50',
  '60': '60',
  'auto': 'auto',
  'dropdown': '1000',
  'sticky': '1100',
  'fixed': '1200',
  'drawer': '1300',
  'modal': '1400',
  'popover': '1500',
  'tooltip': '1600',
};

// Export the complete token system
export default {
  colors,
  spacing,
  typography,
  borders,
  shadows,
  animations,
  zIndex,
};
