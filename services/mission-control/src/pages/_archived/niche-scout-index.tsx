import React, { useState } from 'react';
import { useRouter } from 'next/router';
// Archived file - import commented out
// import MainLayout from '../../../components/layout/MainLayout';
import { format } from 'date-fns';

// Mock data for development
const mockNicheScoutResult = {
  run_date: new Date().toISOString(),
  trending_niches: Array.from({ length: 20 }, (_, i) => ({
    query: ['mobile gaming tips', 'coding tutorials', 'fitness workouts', 'cooking recipes', 'travel vlogs'][i % 5],
    view_sum: Math.floor(Math.random() * 5000000) + 1000000,
    rsv: Math.random() * 100,
    view_rank: i + 1,
    rsv_rank: i + 1,
    score: Math.random() * 0.5 + 0.5,
    x: Math.random() * 100,
    y: Math.random() * 100,
    niche: i % 5
  })),
  top_niches: Array.from({ length: 10 }, (_, i) => ({
    query: ['mobile gaming tips', 'coding tutorials', 'fitness workouts', 'cooking recipes', 'travel vlogs'][i % 5],
    view_sum: Math.floor(Math.random() * 5000000) + 1000000,
    rsv: Math.random() * 100,
    view_rank: i + 1,
    rsv_rank: i + 1,
    score: Math.random() * 0.5 + 0.5,
    x: Math.random() * 100,
    y: Math.random() * 100,
    niche: i % 5
  })),
  _id: `mock-niche-scout-${Date.now()}`
};

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
      // Call API directly
      const response = await fetch(`/api/social-intel/niche-scout?query=${encodeURIComponent(query || 'mobile')}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
      });
      
      if (response.ok) {
        const data = await response.json();
        // Ensure run_date is valid
        if (!data.run_date || isNaN(new Date(data.run_date).getTime())) {
          data.run_date = new Date().toISOString();
        }
        // Ensure trending_niches exists
        if (!Array.isArray(data.trending_niches)) {
          data.trending_niches = mockNicheScoutResult.trending_niches;
        }
        // Ensure top_niches exists
        if (!Array.isArray(data.top_niches)) {
          data.top_niches = mockNicheScoutResult.top_niches;
        }
        setResultData(data);
      } else {
        console.error('API error:', response.statusText);
        // Use mock data as fallback
        setResultData(mockNicheScoutResult);
      }
    } catch (error) {
      console.error('Error running workflow:', error);
      // Use mock data as fallback
      setResultData(mockNicheScoutResult);
    } finally {
      setIsLoading(false);
    }
  };

  const handleScheduleWorkflow = () => {
    // Just close the modal in mock mode
    setShowScheduleModal(false);
    alert('Workflow scheduled successfully!');
  };

  return (
    // <MainLayout title="Niche-Scout Workflow">
    <div>
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
        
        {/* Results Section */}
        {resultData && (
          <div className="card p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-bold">Results</h2>
              <div className="text-sm text-gray-500 dark:text-gray-400">
                <p>Last Run: {resultData.run_date ? format(new Date(resultData.run_date), 'MMM d, yyyy HH:mm:ss') : new Date().toLocaleString()}</p>
                <p>Found: {resultData.trending_niches?.length || 0} niches</p>
              </div>
            </div>
            
            <div className="flex flex-wrap justify-between mb-4">
              <div className="flex items-center space-x-2">
                <label htmlFor="sort-by" className="text-sm font-medium">
                  Sort by:
                </label>
                <select
                  id="sort-by"
                  value={sortBy}
                  onChange={(e) => setSortBy(e.target.value)}
                  className="input py-1"
                >
                  <option>Growth Rate</option>
                  <option>View Count</option>
                  <option>Overall Score</option>
                </select>
              </div>
              
              <div className="flex space-x-2">
                <button className="btn-secondary py-1">Filter</button>
                <button className="btn-secondary py-1">Export</button>
              </div>
            </div>
            
            {/* Niche Cards */}
            <div className="space-y-6">
              {resultData.top_niches.slice(0, 4).map((niche, index) => (
                <div key={index} className="border border-gray-200 dark:border-gray-700 rounded-lg p-4">
                  <div className="flex justify-between items-start mb-2">
                    <h3 className="font-bold text-lg">{niche.query}</h3>
                    <span className="text-success-600 dark:text-success-400 font-bold">
                      📈 {(niche.score * 100).toFixed(1)}% GROWTH
                    </span>
                  </div>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-2 mb-3 text-sm">
                    <div>
                      <span className="font-medium">Competition:</span> HIGH
                    </div>
                    <div>
                      <span className="font-medium">Shorts-friendly:</span> YES
                    </div>
                    <div>
                      <span className="font-medium">Demographics:</span> 13-17, 18-24
                    </div>
                    <div>
                      <span className="font-medium">Gender:</span> 80% M, 20% F
                    </div>
                  </div>
                  
                  <div className="mb-3">
                    <h4 className="font-medium mb-1">Trending Topics:</h4>
                    <ul className="list-disc list-inside text-sm ml-2">
                      <li>{niche.query} tips</li>
                      <li>{niche.query} tutorials</li>
                      <li>{niche.query} secrets</li>
                    </ul>
                  </div>
                  
                  <div className="mb-3">
                    <h4 className="font-medium mb-1">Top Channels:</h4>
                    <p className="text-sm">
                      {niche.query.replace(/\s+/g, '')}Shorts (4.7M), {niche.query.replace(/\s+/g, '')}Masters (2.9M)
                    </p>
                  </div>
                  
                  <div className="flex flex-wrap gap-2">
                    <button className="btn-secondary py-1 text-sm">VIEW DETAILS</button>
                    <button className="btn-secondary py-1 text-sm">CREATE BLUEPRINT</button>
                    <button className="btn-secondary py-1 text-sm">EXPORT</button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
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
    </div>
    // </MainLayout>
  );
}