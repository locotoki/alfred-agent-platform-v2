import React from 'react';
import Shell from '@/components/layout/Shell';
import YouTubeApiTest from '@/components/workflows/YouTubeApiTest';

const YouTubeTestPage = () => {
  return (
    <Shell>
      <div className="container py-6">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-3xl font-bold">YouTube API Test</h1>
        </div>

        <div className="grid grid-cols-1 gap-6">
          <YouTubeApiTest />
        </div>
      </div>
    </Shell>
  );
};

export default YouTubeTestPage;
