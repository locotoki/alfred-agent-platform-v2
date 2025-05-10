import React, { useEffect, useState } from 'react';

/**
 * Props for the FadeIn component
 */
export interface FadeInProps {
  /** Content to be displayed with fade-in effect */
  children: React.ReactNode;
  /** Delay before starting the animation (ms) */
  delay?: number;
  /** Duration of the animation (ms) */
  duration?: number;
  /** Direction to fade from ('up', 'down', 'left', 'right') */
  direction?: 'up' | 'down' | 'left' | 'right' | 'none';
  /** Distance to travel during animation (px) */
  distance?: number;
  /** Whether the element should be visible initially */
  initialVisible?: boolean;
  /** Additional CSS classes */
  className?: string;
}

/**
 * FadeIn Component
 * 
 * Animates children with a fade-in effect
 * 
 * @example
 * ```tsx
 * <FadeIn delay={200} direction="up">
 *   <p>This content will fade in from below</p>
 * </FadeIn>
 * ```
 */
export const FadeIn: React.FC<FadeInProps> = ({
  children,
  delay = 0,
  duration = 300,
  direction = 'none',
  distance = 20,
  initialVisible = false,
  className = '',
}) => {
  const [isVisible, setIsVisible] = useState(initialVisible);
  
  useEffect(() => {
    const timer = setTimeout(() => {
      setIsVisible(true);
    }, delay);
    
    return () => clearTimeout(timer);
  }, [delay]);
  
  // Set initial transform based on direction
  const getInitialTransform = () => {
    switch (direction) {
      case 'up':
        return `translateY(${distance}px)`;
      case 'down':
        return `translateY(-${distance}px)`;
      case 'left':
        return `translateX(${distance}px)`;
      case 'right':
        return `translateX(-${distance}px)`;
      default:
        return 'none';
    }
  };
  
  // Inline styles for the animation
  const styles = {
    opacity: isVisible ? 1 : 0,
    transform: isVisible ? 'none' : getInitialTransform(),
    transition: `opacity ${duration}ms ease, transform ${duration}ms ease`,
  };
  
  return (
    <div className={className} style={styles}>
      {children}
    </div>
  );
};

export default FadeIn;