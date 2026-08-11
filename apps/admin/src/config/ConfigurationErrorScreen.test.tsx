import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { ConfigurationErrorScreen } from './ConfigurationErrorScreen';

describe('ConfigurationErrorScreen', () => {
  it('renders every violation', () => {
    render(
      <ConfigurationErrorScreen
        violations={['VITE_API_BASE_URL is not set.', 'Something else is wrong.']}
      />,
    );

    expect(screen.getByText('Configuration error')).toBeInTheDocument();
    expect(screen.getByText('VITE_API_BASE_URL is not set.')).toBeInTheDocument();
    expect(screen.getByText('Something else is wrong.')).toBeInTheDocument();
  });
});
