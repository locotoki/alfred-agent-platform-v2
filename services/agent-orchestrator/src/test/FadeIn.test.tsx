import React from 'react';
import { render, screen, act } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

// Mock FadeIn component for testing
const FadeIn: React.FC<{
  children: React.ReactNode;
  delay?: number;
  duration?: number;
  direction?: 'up' | 'down' | 'left' | 'right' | 'none';
  distance?: number;
  initialVisible?: boolean;
  className?: string;
  'data-testid'?: string;
}> = ({
  children,
  delay = 0,
  duration = 300,
  direction = 'none',
  distance = 20,
  initialVisible = false,
  className = '',
  'data-testid': testId,
}) => {
  const [isVisible, setIsVisible] = React.useState(initialVisible);
  
  React.useEffect(() => {
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
    <div className={className} style={styles} data-testid={testId}>
      {children}
    </div>
  );
};

describe('FadeIn Component', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.runOnlyPendingTimers();
    vi.useRealTimers();
  });

  it('renders children correctly', async () => {
    await act(async () => {
      render(
        <FadeIn>
          <div data-testid="test-child">Test Content</div>
        </FadeIn>
      );
    });

    expect(screen.getByTestId('test-child')).toBeInTheDocument();
    expect(screen.getByText('Test Content')).toBeInTheDocument();
  });

  it('starts with opacity 0 and transitions to opacity 1 after delay', async () => {
    await act(async () => {
      render(
        <FadeIn delay={500} data-testid="fade-container">
          <div>Test Content</div>
        </FadeIn>
      );
    });

    const container = screen.getByTestId('fade-container');
    
    // Initially should be invisible
    expect(container.style.opacity).toBe('0');
    
    // After delay, should be visible
    await act(async () => {
      vi.advanceTimersByTime(500);
    });
    
    expect(container.style.opacity).toBe('1');
  });

  it('applies transform based on up direction', async () => {
    await act(async () => {
      render(
        <FadeIn direction="up" distance={30} data-testid="fade-up" initialVisible={false}>
          <div>Test Content</div>
        </FadeIn>
      );
    });

    const container = screen.getByTestId('fade-up');
    expect(container.style.transform).toBe('translateY(30px)');
  });
  
  it('applies transform based on down direction', async () => {
    await act(async () => {
      render(
        <FadeIn direction="down" distance={30} data-testid="fade-down" initialVisible={false}>
          <div>Test Content</div>
        </FadeIn>
      );
    });
    
    const container = screen.getByTestId('fade-down');
    expect(container.style.transform).toBe('translateY(-30px)');
  });
  
  it('applies transform based on left direction', async () => {
    await act(async () => {
      render(
        <FadeIn direction="left" distance={30} data-testid="fade-left" initialVisible={false}>
          <div>Test Content</div>
        </FadeIn>
      );
    });
    
    const container = screen.getByTestId('fade-left');
    expect(container.style.transform).toBe('translateX(30px)');
  });
  
  it('applies transform based on right direction', async () => {
    await act(async () => {
      render(
        <FadeIn direction="right" distance={30} data-testid="fade-right" initialVisible={false}>
          <div>Test Content</div>
        </FadeIn>
      );
    });
    
    const container = screen.getByTestId('fade-right');
    expect(container.style.transform).toBe('translateX(-30px)');
  });

  it('respects the initialVisible prop', async () => {
    await act(async () => {
      render(
        <FadeIn initialVisible={true} data-testid="fade-container">
          <div>Test Content</div>
        </FadeIn>
      );
    });

    const container = screen.getByTestId('fade-container');
    
    // Should be visible initially
    expect(container.style.opacity).toBe('1');
    expect(container.style.transform).toBe('none');
  });

  it('applies custom duration', async () => {
    await act(async () => {
      render(
        <FadeIn duration={500} data-testid="fade-container">
          <div>Test Content</div>
        </FadeIn>
      );
    });

    const container = screen.getByTestId('fade-container');
    
    // Check if transition property contains the custom duration
    expect(container.style.transition).toContain('500ms');
  });

  it('applies additional className', async () => {
    await act(async () => {
      render(
        <FadeIn className="custom-class" data-testid="fade-container">
          <div>Test Content</div>
        </FadeIn>
      );
    });

    const container = screen.getByTestId('fade-container');
    expect(container.classList.contains('custom-class')).toBe(true);
  });
});