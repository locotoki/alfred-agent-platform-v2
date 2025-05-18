import { useContext } from 'react';
import { FeatureFlagContext } from '../contexts/FeatureFlagContext';

/**
 * Hook to check if a feature flag is enabled.
 * 
 * @param flagName - The name of the feature flag
 * @returns boolean indicating if the feature is enabled
 */
export function useFeatureFlag(flagName: string): boolean {
  const context = useContext(FeatureFlagContext);
  
  if (!context) {
    // If no context provider, assume all flags are disabled
    return false;
  }
  
  return context.flags[flagName] || false;
}