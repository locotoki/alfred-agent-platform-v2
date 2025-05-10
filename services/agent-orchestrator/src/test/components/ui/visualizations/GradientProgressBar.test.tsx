import React from 'react';
import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { GradientProgressBar } from '../../../../../shared-components/components/ui/visualizations/GradientProgressBar';

describe('GradientProgressBar Component', () => {
  it('renders correctly with default props', () => {
    render(<GradientProgressBar value={50} data-testid="progress" />);
    
    const progressBar = screen.getByTestId('progress');
    expect(progressBar).toBeInTheDocument();
    
    // Check that the inner progress div exists and has correct width
    const innerBar = progressBar.querySelector('div > div');
    expect(innerBar).toHaveStyle('width: 50%');
  });

  it('clamps value between 0 and max', () => {
    const { rerender } = render(<GradientProgressBar value={-10} data-testid="progress" />);
    
    let innerBar = screen.getByTestId('progress').querySelector('div > div');
    expect(innerBar).toHaveStyle('width: 0%');
    
    rerender(<GradientProgressBar value={150} max={100} data-testid="progress" />);
    innerBar = screen.getByTestId('progress').querySelector('div > div');
    expect(innerBar).toHaveStyle('width: 100%');
  });

  it('applies correct gradient based on variant', () => {
    const { rerender } = render(<GradientProgressBar value={50} variant="primary" data-testid="progress" />);
    
    let innerBar = screen.getByTestId('progress').querySelector('div > div');
    expect(innerBar).toHaveClass('from-blue-500 to-blue-600');
    
    rerender(<GradientProgressBar value={50} variant="secondary" data-testid="progress" />);
    innerBar = screen.getByTestId('progress').querySelector('div > div');
    expect(innerBar).toHaveClass('from-purple-500 to-purple-600');
    
    rerender(<GradientProgressBar value={50} variant="success" data-testid="progress" />);
    innerBar = screen.getByTestId('progress').querySelector('div > div');
    expect(innerBar).toHaveClass('from-green-500 to-green-600');
    
    rerender(<GradientProgressBar value={50} variant="warning" data-testid="progress" />);
    innerBar = screen.getByTestId('progress').querySelector('div > div');
    expect(innerBar).toHaveClass('from-yellow-500 to-yellow-600');
    
    rerender(<GradientProgressBar value={50} variant="error" data-testid="progress" />);
    innerBar = screen.getByTestId('progress').querySelector('div > div');
    expect(innerBar).toHaveClass('from-red-500 to-red-600');
  });

  it('renders with custom height', () => {
    render(<GradientProgressBar value={50} height="1rem" data-testid="progress" />);
    
    const container = screen.getByTestId('progress').querySelector('div');
    expect(container).toHaveStyle('height: 1rem');
  });

  it('displays label when provided', () => {
    render(<GradientProgressBar value={50} label="CPU Usage" data-testid="progress" />);
    
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
    
    let innerBar = screen.getByTestId('progress').querySelector('div > div');
    expect(innerBar).toHaveClass('animate-progress');
    expect(innerBar).not.toHaveClass('bg-stripes');
    
    rerender(
      <GradientProgressBar 
        value={50} 
        striped={true} 
        data-testid="progress" 
      />
    );
    
    innerBar = screen.getByTestId('progress').querySelector('div > div');
    expect(innerBar).toHaveClass('bg-stripes');
    expect(innerBar).not.toHaveClass('animate-progress');
    
    rerender(
      <GradientProgressBar 
        value={50} 
        animated={true} 
        striped={true} 
        data-testid="progress" 
      />
    );
    
    innerBar = screen.getByTestId('progress').querySelector('div > div');
    expect(innerBar).toHaveClass('animate-progress');
    expect(innerBar).toHaveClass('bg-stripes');
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