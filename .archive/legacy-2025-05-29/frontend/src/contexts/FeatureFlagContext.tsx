import React, { createContext, useState, useEffect, ReactNode } from 'react';

interface FeatureFlags {
  [key: string]: boolean;
}

interface FeatureFlagContextType {
  flags: FeatureFlags;
  updateFlag: (flagName: string, value: boolean) => void;
}

export const FeatureFlagContext = createContext<FeatureFlagContextType | null>(null);

interface FeatureFlagProviderProps {
  children: ReactNode;
  defaultFlags?: FeatureFlags;
  flagsEndpoint?: string;
}

export const FeatureFlagProvider: React.FC<FeatureFlagProviderProps> = ({
  children,
  defaultFlags = {
    'dynamic-thresholds': false,  // Default to disabled
  },
  flagsEndpoint = '/api/feature-flags'
}) => {
  const [flags, setFlags] = useState<FeatureFlags>(defaultFlags);

  useEffect(() => {
    // Fetch feature flags from backend if endpoint provided
    if (flagsEndpoint) {
      fetch(flagsEndpoint)
        .then(res => res.json())
        .then(data => setFlags({ ...defaultFlags, ...data }))
        .catch(() => {
          // Fall back to defaults on error
          console.warn('Failed to fetch feature flags, using defaults');
        });
    }
  }, [flagsEndpoint]);

  const updateFlag = (flagName: string, value: boolean) => {
    setFlags(prev => ({
      ...prev,
      [flagName]: value
    }));
  };

  return (
    <FeatureFlagContext.Provider value={{ flags, updateFlag }}>
      {children}
    </FeatureFlagContext.Provider>
  );
};
