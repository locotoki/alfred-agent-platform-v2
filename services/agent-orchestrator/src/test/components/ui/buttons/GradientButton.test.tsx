import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { GradientButton } from '../../../../../shared-components/components/ui/buttons/GradientButton';

describe('GradientButton Component', () => {
  it('renders children correctly', () => {
    render(
      <GradientButton>Click Me</GradientButton>
    );

    expect(screen.getByText('Click Me')).toBeInTheDocument();
  });

  it('calls onClick handler when clicked', () => {
    const handleClick = vi.fn();

    render(
      <GradientButton onClick={handleClick}>Click Me</GradientButton>
    );

    fireEvent.click(screen.getByText('Click Me'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('does not call onClick when disabled', () => {
    const handleClick = vi.fn();

    render(
      <GradientButton onClick={handleClick} disabled>Click Me</GradientButton>
    );

    fireEvent.click(screen.getByText('Click Me'));
    expect(handleClick).not.toHaveBeenCalled();
  });

  it('applies different size classes correctly', () => {
    const { rerender } = render(
      <GradientButton size="xs" data-testid="button">Click Me</GradientButton>
    );

    let button = screen.getByTestId('button');
    expect(button).toHaveClass('px-2.5 py-1.5 text-xs');

    rerender(
      <GradientButton size="sm" data-testid="button">Click Me</GradientButton>
    );

    button = screen.getByTestId('button');
    expect(button).toHaveClass('px-3 py-2 text-sm');

    rerender(
      <GradientButton size="md" data-testid="button">Click Me</GradientButton>
    );

    button = screen.getByTestId('button');
    expect(button).toHaveClass('px-4 py-2 text-sm');

    rerender(
      <GradientButton size="lg" data-testid="button">Click Me</GradientButton>
    );

    button = screen.getByTestId('button');
    expect(button).toHaveClass('px-4 py-2 text-base');

    rerender(
      <GradientButton size="xl" data-testid="button">Click Me</GradientButton>
    );

    button = screen.getByTestId('button');
    expect(button).toHaveClass('px-6 py-3 text-base');
  });

  it('applies correct gradient based on variant', () => {
    const { rerender } = render(
      <GradientButton variant="primary" data-testid="button">Click Me</GradientButton>
    );

    let button = screen.getByTestId('button');
    expect(button).toHaveClass('from-blue-500 to-blue-600');

    rerender(
      <GradientButton variant="secondary" data-testid="button">Click Me</GradientButton>
    );

    button = screen.getByTestId('button');
    expect(button).toHaveClass('from-purple-500 to-purple-600');

    rerender(
      <GradientButton variant="success" data-testid="button">Click Me</GradientButton>
    );

    button = screen.getByTestId('button');
    expect(button).toHaveClass('from-green-500 to-green-600');

    rerender(
      <GradientButton variant="warning" data-testid="button">Click Me</GradientButton>
    );

    button = screen.getByTestId('button');
    expect(button).toHaveClass('from-yellow-500 to-yellow-600');

    rerender(
      <GradientButton variant="error" data-testid="button">Click Me</GradientButton>
    );

    button = screen.getByTestId('button');
    expect(button).toHaveClass('from-red-500 to-red-600');
  });

  it('applies disabled styling when disabled', () => {
    render(
      <GradientButton disabled data-testid="button">Click Me</GradientButton>
    );

    const button = screen.getByTestId('button');
    expect(button).toHaveClass('cursor-not-allowed opacity-60');
    expect(button).toHaveClass('bg-gray-300 dark:bg-gray-700');
    expect(button).toBeDisabled();
  });

  it('shows loading indicator when loading', () => {
    render(
      <GradientButton loading data-testid="button">Click Me</GradientButton>
    );

    const button = screen.getByTestId('button');
    expect(button).toBeDisabled();
    expect(screen.getByText('Click Me')).toBeInTheDocument();

    // Check for the loading spinner
    const spinner = document.querySelector('svg.animate-spin');
    expect(spinner).toBeInTheDocument();
  });

  it('applies fullWidth styling when requested', () => {
    render(
      <GradientButton fullWidth data-testid="button">Click Me</GradientButton>
    );

    const button = screen.getByTestId('button');
    expect(button).toHaveClass('w-full');
  });

  it('renders iconBefore correctly', () => {
    render(
      <GradientButton iconBefore={<span data-testid="icon-before">👈</span>}>Click Me</GradientButton>
    );

    expect(screen.getByTestId('icon-before')).toBeInTheDocument();

    // Check that icon is positioned correctly
    const iconElement = screen.getByTestId('icon-before');
    expect(iconElement.parentElement).toHaveClass('mr-2');
  });

  it('renders iconAfter correctly', () => {
    render(
      <GradientButton iconAfter={<span data-testid="icon-after">👉</span>}>Click Me</GradientButton>
    );

    expect(screen.getByTestId('icon-after')).toBeInTheDocument();

    // Check that icon is positioned correctly
    const iconElement = screen.getByTestId('icon-after');
    expect(iconElement.parentElement).toHaveClass('ml-2');
  });

  it('applies custom className', () => {
    render(
      <GradientButton className="custom-class" data-testid="button">Click Me</GradientButton>
    );

    const button = screen.getByTestId('button');
    expect(button).toHaveClass('custom-class');
  });

  it('sets the button type correctly', () => {
    const { rerender } = render(
      <GradientButton type="button" data-testid="button">Click Me</GradientButton>
    );

    let button = screen.getByTestId('button');
    expect(button).toHaveAttribute('type', 'button');

    rerender(
      <GradientButton type="submit" data-testid="button">Click Me</GradientButton>
    );

    button = screen.getByTestId('button');
    expect(button).toHaveAttribute('type', 'submit');

    rerender(
      <GradientButton type="reset" data-testid="button">Click Me</GradientButton>
    );

    button = screen.getByTestId('button');
    expect(button).toHaveAttribute('type', 'reset');
  });
});
