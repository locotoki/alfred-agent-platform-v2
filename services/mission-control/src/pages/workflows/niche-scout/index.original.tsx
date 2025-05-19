import React, { useState } from 'react';
import { useRouter } from 'next/router';
import MainLayout from '../../../components/layout/MainLayout';
import { format } from 'date-fns';
import { runNicheScout } from '../../../services/youtube-workflows';

export default function NicheScout() {
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [category, setCategory] = useState('All');
  const [timeRange, setTimeRange] = useState('Last 30 days');
  const [demographics, setDemographics] = useState('All');
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [sortBy, setSortBy] = useState('Growth Rate');
  const [resultData, setResultData] = useState(null);
  const [isLoading, setIsLoading] = useState(false);
  const [showScheduleModal, setShowScheduleModal] = useState(false);
  const [frequency, setFrequency] = useState('daily');
  const [runDate, setRunDate] = useState('');

  const handleRunWorkflow = async () => {
    setIsLoading(true);
    try {
      // Call workflow service to run niche scout
      const result = await runNicheScout(query);
      setResultData(result);

      // If the result has an ID, navigate to the results page
      if (result._id) {
        router.push(`/workflows/niche-scout/results/${result._id}`);
      }
    } catch (error) {
      console.error('Error running workflow:', error);
      setIsLoading(false);
    }
  };

  const handleScheduleWorkflow = () => {
    // Just close the modal in mock mode
    setShowScheduleModal(false);
    alert('Workflow scheduled successfully!');
  };

  return (
    <MainLayout title="Niche-Scout Workflow">
      <div className="space-y-6">
        <div className="pb-5 border-b border-gray-200 dark:border-gray-700 mb-6">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Niche-Scout Workflow
          </h1>
        </div>

        {/* Configuration Section */}
        <div className="card p-6">
          <h2 className="text-xl font-bold mb-4">Configuration</h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label htmlFor="niche-query" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Niche Query
              </label>
              <input
                id="niche-query"
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="e.g. gaming, cooking, fitness"
                className="input w-full"
              />
            </div>
            <div>
              <label htmlFor="category" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Category
              </label>
              <select
                id="category"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="input w-full"
              >
                <option>All</option>
                <option>Gaming</option>
                <option>Education</option>
                <option>Entertainment</option>
                <option>Howto & Style</option>
                <option>Science & Technology</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label htmlFor="time-range" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Time Range
              </label>
              <select
                id="time-range"
                value={timeRange}
                onChange={(e) => setTimeRange(e.target.value)}
                className="input w-full"
              >
                <option>Last 7 days</option>
                <option>Last 30 days</option>
                <option>Last 90 days</option>
                <option>Last 12 months</option>
              </select>
            </div>
            <div>
              <label htmlFor="demographics" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Demographics
              </label>
              <select
                id="demographics"
                value={demographics}
                onChange={(e) => setDemographics(e.target.value)}
                className="input w-full"
              >
                <option>All</option>
                <option>13-17</option>
                <option>18-24</option>
                <option>25-34</option>
                <option>35-44</option>
                <option>45+</option>
              </select>
            </div>
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
                  <label htmlFor="min-views" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Minimum Views
                  </label>
                  <input
                    id="min-views"
                    type="number"
                    placeholder="e.g. 10000"
                    className="input w-full"
                  />
                </div>
                <div>
                  <label htmlFor="min-growth" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Minimum Growth (%)
                  </label>
                  <input
                    id="min-growth"
                    type="number"
                    placeholder="e.g. 20"
                    className="input w-full"
                  />
                </div>
              </div>
            </div>
          )}

          <div className="flex flex-wrap gap-3">
            <button
              onClick={handleRunWorkflow}
              disabled={isLoading}
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
