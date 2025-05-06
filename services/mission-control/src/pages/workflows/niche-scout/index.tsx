import { useState } from 'react';
import { useRouter } from 'next/router';
import MainLayout from '../../../components/layout/MainLayout';
import { runNicheScout } from '../../../services/youtube-workflows';

export default function NicheScout() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showAdvanced, setShowAdvanced] = useState(false);
  
  // Form state
  const [formData, setFormData] = useState({
    query: '',
    category: 'All',
    timeRange: 'Last 30 days',
    demographics: 'All',
  });

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    try {
      // Show a user-friendly message
      console.log('Running Niche-Scout workflow...');
      
      // Run the workflow
      const result = await runNicheScout(formData.query);
      
      // Navigate to results page with ID
      router.push(`/workflows/niche-scout/results/${result.run_date.replace(/[^a-zA-Z0-9]/g, '')}`);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unexpected error occurred');
      console.error('Niche-Scout workflow error:', err);
      setIsLoading(false);
    }
  };

  return (
    <MainLayout title="Niche-Scout Workflow">
      <div className="space-y-6">
        <div className="pb-5 border-b border-gray-200 dark:border-gray-700 mb-6">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              NICHE-SCOUT WORKFLOW
            </h1>
            <button 
              onClick={() => router.back()}
              className="btn-secondary"
            >
              Back
            </button>
          </div>
        </div>

        <div className="card p-6">
          <h2 className="text-xl font-bold mb-4">Find Trending YouTube Niches</h2>
          <p className="text-gray-600 dark:text-gray-400 mb-6">
            Discover high-potential YouTube niches with growth metrics, trend analysis, and visualization.
          </p>

          {error && (
            <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-800 dark:text-red-200 p-4 mb-6 rounded-md">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="space-y-4">
              <div>
                <label htmlFor="query" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Search Query
                </label>
                <input
                  type="text"
                  id="query"
                  name="query"
                  placeholder="e.g., mobile gaming tips, AI tutorials, cooking recipes"
                  className="input-field w-full"
                  value={formData.query}
                  onChange={handleChange}
                  required
                />
                <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                  Enter a niche or topic to analyze on YouTube
                </p>
              </div>

              <div>
                <button
                  type="button"
                  className="text-sm text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 underline"
                  onClick={() => setShowAdvanced(!showAdvanced)}
                >
                  {showAdvanced ? 'Hide Advanced Options' : 'Show Advanced Options'}
                </button>
              </div>

              {showAdvanced && (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div>
                    <label htmlFor="category" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Category
                    </label>
                    <select
                      id="category"
                      name="category"
                      className="select-field w-full"
                      value={formData.category}
                      onChange={handleChange}
                    >
                      <option value="All">All Categories</option>
                      <option value="Gaming">Gaming</option>
                      <option value="Entertainment">Entertainment</option>
                      <option value="Music">Music</option>
                      <option value="Education">Education</option>
                      <option value="HowTo">How-To & DIY</option>
                      <option value="Science">Science & Tech</option>
                      <option value="Sports">Sports</option>
                      <option value="Travel">Travel</option>
                      <option value="Food">Food</option>
                      <option value="Beauty">Beauty & Fashion</option>
                    </select>
                  </div>

                  <div>
                    <label htmlFor="timeRange" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Time Range
                    </label>
                    <select
                      id="timeRange"
                      name="timeRange"
                      className="select-field w-full"
                      value={formData.timeRange}
                      onChange={handleChange}
                    >
                      <option value="Last 7 days">Last 7 days</option>
                      <option value="Last 30 days">Last 30 days</option>
                      <option value="Last 90 days">Last 90 days</option>
                      <option value="Last 12 months">Last 12 months</option>
                    </select>
                  </div>

                  <div>
                    <label htmlFor="demographics" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                      Demographics
                    </label>
                    <select
                      id="demographics"
                      name="demographics"
                      className="select-field w-full"
                      value={formData.demographics}
                      onChange={handleChange}
                    >
                      <option value="All">All Ages</option>
                      <option value="13-17">13-17</option>
                      <option value="18-24">18-24</option>
                      <option value="25-34">25-34</option>
                      <option value="35-44">35-44</option>
                      <option value="45-54">45-54</option>
                      <option value="55+">55+</option>
                    </select>
                  </div>
                </div>
              )}

              <div className="flex items-center justify-between pt-4">
                <button
                  type="button"
                  className="btn-secondary"
                  onClick={() => router.push('/workflows')}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-primary"
                  disabled={isLoading}
                >
                  {isLoading ? (
                    <>
                      <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                      </svg>
                      Processing...
                    </>
                  ) : (
                    'Run Workflow'
                  )}
                </button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </MainLayout>
  );
}