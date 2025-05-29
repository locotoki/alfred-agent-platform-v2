# Shared Components Library

This directory contains shared UI components that can be used across both mission-control and agent-orchestrator during the UI migration process.

## Directory Structure

```
/shared/components/
  /ui/              # Basic UI components
    /cards/         # Card components including StatsCard
    /buttons/       # Button components with gradient styling
    /forms/         # Form input components
    /feedback/      # Loading indicators, alerts, toasts
    /animations/    # Animation components
  /layout/          # Layout components
  /theme/           # Theming components
  /wizards/         # Wizard components for workflows
  /visualizations/  # Data visualization components
```

## Usage

### In Agent Orchestrator (Vite/React)

1. Create a symbolic link to the shared components directory:

```bash
cd /home/locotoki/projects/alfred-agent-platform-v2/services/agent-orchestrator/src
ln -s ../../../shared shared
```

2. Import components in your TSX files:

```tsx
import { GradientButton } from '../../../shared/components/ui/buttons/GradientButton';

// Use the component
<GradientButton variant="primary">Click Me</GradientButton>
```

### In Mission Control (Next.js)

1. Create a symbolic link to the shared components directory:

```bash
cd /home/locotoki/projects/alfred-agent-platform-v2/services/mission-control/src
ln -s ../../../shared shared
```

2. Import components in your TSX files:

```tsx
import { StatsCard } from '../../../shared/components/ui/cards/StatsCard';

// Use the component
<StatsCard
  title="Active Tasks"
  value={127}
  trend={{ value: 12, isPositive: true }}
/>
```

## Component Guidelines

1. **Typescript**: All components should use TypeScript with proper type definitions
2. **Design Tokens**: Use the shared design tokens from `shared/styles/design-tokens.js`
3. **Responsive**: All components should be responsive by default
4. **A11y**: Follow accessibility best practices
5. **Props API**: Keep component props consistent and intuitive
6. **Documentation**: Include PropTypes and usage examples in comments

## Creating New Components

When creating a new shared component:

1. Create the component file in the appropriate directory
2. Export TypeScript interfaces for props
3. Use design tokens for styling
4. Include PropTypes documentation
5. Add basic usage examples as comments

Example:

```tsx
import React from 'react';
import { colors, shadows, borders } from '../../../styles/design-tokens';

/**
 * Props for the GradientCard component
 */
export interface GradientCardProps {
  /** Title to display */
  title: string;
  /** Content to display inside the card */
  children: React.ReactNode;
  /** Gradient variant to use */
  variant?: 'primary' | 'secondary' | 'success';
  /** Additional CSS classes */
  className?: string;
}

/**
 * GradientCard Component
 *
 * Displays content in a card with a gradient background
 *
 * @example
 * ```tsx
 * <GradientCard title="Statistics" variant="primary">
 *   <p>Card content goes here</p>
 * </GradientCard>
 * ```
 */
export const GradientCard: React.FC<GradientCardProps> = ({
  title,
  children,
  variant = 'primary',
  className = '',
}) => {
  // Get gradient based on variant
  const gradientBg = colors[variant]?.gradient || colors.primary.gradient;

  return (
    <div
      className={`rounded-${borders.borderRadius.lg} shadow-${shadows.md} overflow-hidden ${className}`}
      style={{ background: gradientBg }}
    >
      <div className="p-4">
        <h3 className="text-white text-lg font-semibold">{title}</h3>
      </div>
      <div className="bg-white dark:bg-gray-800 p-4">
        {children}
      </div>
    </div>
  );
};
```

## Migration Process

As components are migrated:

1. Extract the component from mission-control
2. Create a shared version using design tokens
3. Update the mission-control version to use the shared component
4. Implement the shared component in agent-orchestrator
5. Update the feature parity checklist

This approach ensures gradual migration without breaking existing functionality.
