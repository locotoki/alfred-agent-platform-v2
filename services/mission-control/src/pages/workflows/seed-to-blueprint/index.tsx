import React, { useState } from 'react';
import { useRouter } from 'next/router';
import MainLayout from '../../../components/layout/MainLayout';
import { runSeedToBlueprint } from '../../../services/youtube-workflows';

export default function SeedToBlueprint() {
  const router = useRouter();
  const [videoUrl, setVideoUrl] = useState('');
  const [niche, setNiche] = useState('');
  const [analysisDepth, setAnalysisDepth] = useState('standard');
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [showScheduleModal, setShowScheduleModal] = useState(false);
  const [frequency, setFrequency] = useState('once');
  const [runDate, setRunDate] = useState('');

  const handleInputChange = (setter) => (e) => {
    setter(e.target.value);
  };

  const handleRunWorkflow = async () => {
    if (!videoUrl && !niche) {
      alert('Please enter either a video URL or a niche keyword');
      return;
    }

    setIsLoading(true);
    try {
      // Call workflow service to run blueprint generation
      const result = await runSeedToBlueprint({
        video_url: videoUrl,
        niche: niche,
        analysisDepth: analysisDepth
      });

      // Navigate to results page with the result ID
      if (result._id) {
        router.push(`/workflows/seed-to-blueprint/results/${result._id}`);
      }
    } catch (error) {
      console.error('Error running workflow:', error);
      setIsLoading(false);
    }
  };

  const handleScheduleWorkflow = () => {
    setShowScheduleModal(false);
    alert('Workflow scheduled successfully!');
  };

  return (
    <MainLayout title="Seed-to-Blueprint Workflow">
      <div className="space-y-6">
        <div className="pb-5 border-b border-gray-200 dark:border-gray-700 mb-6">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Seed-to-Blueprint Workflow
          </h1>
        </div>

        {/* Configuration Section */}
        <div className="card p-6">
          <h2 className="text-xl font-bold mb-4">Configuration</h2>

          <div className="mb-6">
            <p className="text-gray-600 dark:text-gray-400 mb-4">
              Use an existing YouTube video as a seed to generate a channel blueprint, or enter a niche to create a strategy from scratch.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
            <div className="card bg-gray-50 dark:bg-gray-800 p-4">
              <h3 className="font-semibold mb-3">Option 1: Use Video as Seed</h3>
              <label htmlFor="video-url" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                YouTube Video URL
              </label>
              <input
                id="video-url"
                type="text"
                value={videoUrl}
                onChange={handleInputChange(setVideoUrl)}
                placeholder="e.g. https://youtube.com/watch?v=dQw4w9WgXcQ"
                className="input w-full mb-2"
              />
              <p className="text-xs text-gray-500 dark:text-gray-400">
                Enter the URL of a successful video in your target niche
              </p>
            </div>

            <div className="card bg-gray-50 dark:bg-gray-800 p-4">
              <h3 className="font-semibold mb-3">Option 2: Create from Niche</h3>
              <label htmlFor="niche" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Niche Keyword
              </label>
              <input
                id="niche"
                type="text"
                value={niche}
                onChange={handleInputChange(setNiche)}
                placeholder="e.g. programming tutorials, cooking recipes"
                className="input w-full mb-2"
              />
              <p className="text-xs text-gray-500 dark:text-gray-400">
                Enter a niche keyword to generate a channel strategy from scratch
              </p>
            </div>
          </div>

          <div className="mb-4">
            <label htmlFor="analysis-depth" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Analysis Depth
            </label>
            <select
              id="analysis-depth"
              value={analysisDepth}
              onChange={handleInputChange(setAnalysisDepth)}
              className="input w-full mb-2"
            >
              <option value="basic">Basic - Faster results, less detail</option>
              <option value="standard">Standard - Balanced depth and speed</option>
              <option value="deep">Deep - Maximum detail, slower processing</option>
            </select>
          </div>

          <div className="mb-4">
            <button
              onClick={() => setShowAdvanced(!showAdvanced)}
              className="btn-secondary"
            >
              {showAdvanced ? '- Hide Advanced Options' : '+ Advanced Options'}
            </button>
          </div>

          {showAdvanced && (
            <div className="border border-gray-200 dark:border-gray-700 rounded-md p-4 mb-4">
              <h3 className="text-lg font-semibold mb-2">Advanced Options</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label htmlFor="competitor-count" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Number of Competitors to Analyze
                  </label>
                  <input
                    id="competitor-count"
                    type="number"
                    defaultValue={5}
                    min={1}
                    max={10}
                    className="input w-full"
                  />
                </div>
                <div>
                  <label htmlFor="content-focus" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Content Focus
                  </label>
                  <select
                    id="content-focus"
                    defaultValue="balanced"
                    className="input w-full"
                  >
                    <option value="trending">Trending Topics</option>
                    <option value="evergreen">Evergreen Content</option>
                    <option value="balanced">Balanced Approach</option>
                  </select>
                </div>
              </div>
            </div>
          )}

          <div className="flex flex-wrap gap-3">
            <button
              onClick={handleRunWorkflow}
              disabled={isLoading || (!videoUrl && !niche)}
              className="btn-primary"
            >
              {isLoading ? 'Running...' : 'RUN NOW'}
            </button>
            <button
              onClick={() => setShowScheduleModal(true)}
              className="btn-secondary"
            >
              SCHEDULE
            </button>
            <button
              className="btn-secondary"
            >
              SAVE AS TEMPLATE
            </button>
          </div>
        </div>
      </div>

      {/* Schedule Modal */}
      {showScheduleModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full">
            <h2 className="text-xl font-bold mb-4">Schedule Workflow</h2>

            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Frequency
              </label>
              <select
                value={frequency}
                onChange={(e) => setFrequency(e.target.value)}
                className="input w-full"
              >
                <option value="daily">Daily</option>
                <option value="weekly">Weekly</option>
                <option value="monthly">Monthly</option>
                <option value="once">Once</option>
              </select>
            </div>

            {frequency === 'once' && (
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Run Date
                </label>
                <input
                  type="datetime-local"
                  value={runDate}
                  onChange={(e) => setRunDate(e.target.value)}
                  className="input w-full"
                />
              </div>
            )}

            <div className="flex justify-end space-x-2">
              <button
                onClick={() => setShowScheduleModal(false)}
                className="btn-secondary"
              >
                Cancel
              </button>
              <button
                onClick={handleScheduleWorkflow}
                className="btn-primary"
              >
                Schedule
              </button>
            </div>
          </div>
        </div>
      )}
    </MainLayout>
  );
}
