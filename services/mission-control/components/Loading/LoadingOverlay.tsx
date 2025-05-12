import React from 'react';

interface LoadingOverlayProps {
  message?: string;
  isVisible: boolean;
  resultId?: string | null;
  resultType?: 'niche-scout' | 'seed-to-blueprint';
}

export default function LoadingOverlay({ 
  message = 'Processing...', 
  isVisible, 
  resultId = null,
  resultType = 'niche-scout'
}: LoadingOverlayProps) {
  if (!isVisible) return null;
  
  // Generate results URL if we have a result ID
  const resultsUrl = resultId ? `/workflows/${resultType}/results/${resultId}` : null;
  
  return (
    <div className="loading-overlay">
      <div className="loading-container flex flex-col items-center">
        <div className="loading-spinner mb-4"></div>
        <h2 className="heading-2 mb-2">{message}</h2>
        <p className="body-text text-center mb-4">
          This may take a few moments. Please don't close this page.
        </p>
        
        {/* Show manual navigation button if we have a result ID */}
        {resultId && resultsUrl && (
          <div className="mt-4">
            <a 
              href={resultsUrl}
              className="button-primary"
            >
              View Results Now
            </a>
          </div>
        )}
      </div>
    </div>
  );
}