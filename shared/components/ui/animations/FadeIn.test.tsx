import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { FadeIn } from '/home/locotoki/projects/alfred-agent-platform-v2/shared/components/ui/animations/FadeIn';

describe('FadeIn Component', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.runOnlyPendingTimers();
    vi.useRealTimers();
  });

  it('renders children correctly', () => {
    render(
      <FadeIn>
        <div data-testid="test-child">Test Content</div>
      </FadeIn>
    );

    expect(screen.getByTestId('test-child')).toBeInTheDocument();
    expect(screen.getByText('Test Content')).toBeInTheDocument();
  });

  it('starts with opacity 0 and transitions to opacity 1 after delay', () => {
    render(
      <FadeIn delay={500} data-testid="fade-container">
        <div>Test Content</div>
      </FadeIn>
    );

    const container = screen.getByTestId('fade-container');
    
    // Initially should be invisible
    expect(container.style.opacity).toBe('0');
    
    // After delay, should be visible
    vi.advanceTimersByTime(500);
    expect(container.style.opacity).toBe('1');
  });

  it('applies correct transform based on direction prop', () => {
    const { rerender } = render(
      <FadeIn direction="up" distance={30} data-testid="fade-container">
        <div>Test Content</div>
      </FadeIn>
    );

    const container = screen.getByTestId('fade-container');
    
    // Initial transform should match direction
    expect(container.style.transform).toBe('translateY(30px)');
    
    // After animation completes
    vi.advanceTimersByTime(1000);
    expect(container.style.transform).toBe('none');
    
    // Test with "down" direction
    rerender(
      <FadeIn direction="down" distance={30} data-testid="fade-container">
        <div>Test Content</div>
      </FadeIn>
    );
    
    // Reset animation state
    vi.advanceTimersByTime(0);
    expect(container.style.transform).toBe('translateY(-30px)');
    
    // Test with "left" direction
    rerender(
      <FadeIn direction="left" distance={30} data-testid="fade-container">
        <div>Test Content</div>
      </FadeIn>
    );
    
    // Reset animation state
    vi.advanceTimersByTime(0);
    expect(container.style.transform).toBe('translateX(30px)');
    
    // Test with "right" direction
    rerender(
      <FadeIn direction="right" distance={30} data-testid="fade-container">
        <div>Test Content</div>
      </FadeIn>
    );
    
    // Reset animation state
    vi.advanceTimersByTime(0);
    expect(container.style.transform).toBe('translateX(-30px)');
  });

  it('respects the initialVisible prop', () => {
    render(
      <FadeIn initialVisible={true} data-testid="fade-container">
        <div>Test Content</div>
      </FadeIn>
    );

    const container = screen.getByTestId('fade-container');
    
    // Should be visible initially
    expect(container.style.opacity).toBe('1');
    expect(container.style.transform).toBe('none');
  });

  it('applies custom duration', () => {
    render(
      <FadeIn duration={500} data-testid="fade-container">
        <div>Test Content</div>
      </FadeIn>
    );

    const container = screen.getByTestId('fade-container');
    
    // Check if transition property contains the custom duration
    expect(container.style.transition).toContain('500ms');
  });

  it('applies additional className', () => {
    render(
      <FadeIn className="custom-class" data-testid="fade-container">
        <div>Test Content</div>
      </FadeIn>
    );

    const container = screen.getByTestId('fade-container');
    expect(container.classList.contains('custom-class')).toBe(true);
  });
});