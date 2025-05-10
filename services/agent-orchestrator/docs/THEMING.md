# Theme System Documentation

The Alfred Agent Orchestrator now includes a comprehensive theming system that supports both light and dark modes. This document explains how the theme system works and how to extend it.

## Theme Architecture

The theming system is built using:
- React Context API for state management
- Local Storage for theme persistence
- CSS Variables for dynamic styling
- Tailwind CSS for utility classes

### Key Components

1. **ThemeProvider**: Located at `src/components/theme/ThemeProvider.tsx`
   - Manages theme state
   - Provides theme context to all child components
   - Handles theme persistence in local storage
   - Detects system preference when no theme is set

2. **ThemeToggle**: Located at `src/components/theme/ThemeToggle.tsx`
   - UI component for toggling between themes
   - Displays current theme status
   - Allows switching between light, dark, and system theme

3. **Tailwind Configuration**: Located at `tailwind.config.ts`
   - Defines color palettes for light and dark modes
   - Sets up CSS variables for theme colors
   - Configures the dark mode variant

## How It Works

1. The `ThemeProvider` wraps the application and provides:
   - Current theme state (`light`, `dark`, or `system`)
   - Functions to change the theme
   - Theme loading and persistence logic

2. When the theme changes:
   - The `dark` class is added to or removed from the document root
   - The theme preference is stored in local storage
   - CSS variables update to reflect the new theme

3. Components use:
   - Tailwind's dark mode variants (e.g., `dark:bg-gray-800`)
   - CSS variables for custom styling (e.g., `var(--primary)`)

## Usage in Components

### Using Theme-Aware Components

```tsx
// Example of a theme-aware component
import { Button } from "@/components/ui/button";

export function MyComponent() {
  return (
    <div className="bg-background text-foreground">
      <h1 className="text-primary">Hello World</h1>
      <Button variant="default">Click Me</Button>
    </div>
  );
}
```

### Programmatically Accessing Theme

```tsx
// Example of using the theme context
import { useTheme } from "@/components/theme/ThemeProvider";

export function ThemeAwareComponent() {
  const { theme, setTheme } = useTheme();
  
  return (
    <div>
      <p>Current theme: {theme}</p>
      <button onClick={() => setTheme("light")}>Light</button>
      <button onClick={() => setTheme("dark")}>Dark</button>
      <button onClick={() => setTheme("system")}>System</button>
    </div>
  );
}
```

## Extending the Theme

### Adding New Colors

To add new theme colors, update the Tailwind configuration in `tailwind.config.ts`:

```ts
// Example of adding a new color
const config = {
  theme: {
    extend: {
      colors: {
        "custom-color": {
          light: "#ffaa00",
          dark: "#885500",
        },
      },
    },
  },
};
```

### Creating Themed Components

Create components that adapt to the current theme:

```tsx
// Example of a themed component
export function ThemedCard({ children }) {
  return (
    <div className="bg-card text-card-foreground rounded-lg shadow-sm dark:shadow-md transition-colors duration-200">
      {children}
    </div>
  );
}
```

## Best Practices

1. Always use Tailwind's semantic color names instead of direct color values:
   - `bg-background` instead of `bg-white`
   - `text-primary` instead of `text-blue-500`

2. Use the `dark:` variant for dark mode specific styling:
   - `dark:bg-gray-800`
   - `dark:text-gray-100`

3. For animations and transitions when switching themes:
   - Add `transition-colors` to elements that change color
   - Use `duration-200` for smooth transitions

4. For custom CSS, use CSS variables defined in the Tailwind config:
   - `var(--primary)` instead of hard-coded colors