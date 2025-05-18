import { useState } from 'react';
import { useRouter } from 'next/router';
// Archived file - imports commented out
// import MainLayout from '../../../components/layout/MainLayout';
// import { runSeedToBlueprint } from '../../../services/youtube-workflows';

export default function SeedToBlueprint() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [inputType, setInputType] = useState<'video' | 'niche'>('video');

  // Form state
  const [formData, setFormData] = useState({
    video_url: '',
    niche: '',
    analysisDepth: 'Standard'
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
      // Determine whether we're using a video URL or niche
      const sourceType = inputType === 'video' ? 'video URL' : 'niche';
      const sourceValue = inputType === 'video' ? formData.video_url : formData.niche;
      console.log(`Running Seed-to-Blueprint workflow with ${sourceType}: ${sourceValue}...`);
      console.log('Form data:', formData);

      // Validate input
      if (!sourceValue) {
        throw new Error(`Please provide a valid ${sourceType}`);
      }

      // Run the workflow with the appropriate parameters
      const params = inputType === 'video'
        ? { video_url: formData.video_url, analysisDepth: formData.analysisDepth }
        : { niche: formData.niche, analysisDepth: formData.analysisDepth };

      // Try to run the workflow with direct fetch call to ensure correct port
      let result;
      try {
        console.log('This is an archived file and the actual API call is commented out.');
        // Commented out for archived file
        /*
        // Build the query parameters
        const params = new URLSearchParams();
        if (inputType === 'video') {
          params.append('video_url', formData.video_url);
        } else {
          params.append('niche', formData.niche.toLowerCase());
        }
        params.append('analysisDepth', formData.analysisDepth);

        // Build the URL using window.location.origin to ensure correct port
        const apiUrl = `${window.location.origin}/api/social-intel/seed-to-blueprint?${params.toString()}`;
        console.log('Using API URL:', apiUrl);

        const response = await fetch(apiUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          }
        });

        if (!response.ok) {
          throw new Error(`API returned status ${response.status}`);
        }

        result = await response.json();
        console.log('API response:', result);
        */
        // Using mock result for archived file
        result = { _id: 'mock-archived-blueprint' };
      } catch (apiError) {
        console.error('API call failed:', apiError);
        throw new Error(`API Error: ${apiError instanceof Error ? apiError.message : 'Unknown error'}`);
      }

      if (!result) {
        throw new Error('No result returned from the API');
      }

      // Navigate to results page with ID
      // If the result has an _id field, use that, otherwise generate a unique ID
      const resultId = result._id || `blueprint-${new Date().getTime()}-${Math.random().toString(36).substring(2, 10)}`;

      // Log the successful workflow execution and redirect
      console.log(`Seed-to-Blueprint workflow completed successfully with ID: ${resultId}`);

      // Use a slight delay to ensure the API has time to process before redirect
      setTimeout(() => {
        router.push(`/workflows/seed-to-blueprint/results/${resultId}?dev_bypass_auth=true`);
      }, 500);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An unexpected error occurred');
      console.error('Seed-to-Blueprint workflow error:', err);
      setIsLoading(false);
    }
  };

  return (
    // <MainLayout title="Seed-to-Blueprint Workflow">
    <div>
      <div className="space-y-6">
        <div className="pb-5 border-b border-gray-200 dark:border-gray-700 mb-6">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              SEED-TO-BLUEPRINT WORKFLOW
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
          <h2 className="text-xl font-bold mb-4">Create Channel Blueprint</h2>
          <p className="text-gray-600 dark:text-gray-400 mb-6">
            Generate a comprehensive YouTube channel strategy based on a seed video or niche.
          </p>

          {error && (
            <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-800 dark:text-red-200 p-4 mb-6 rounded-md">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="space-y-4">
              <div className="flex items-center space-x-4 mb-4">
                <label className="inline-flex items-center">
                  <input
                    type="radio"
                    className="form-radio"
                    name="inputType"
                    checked={inputType === 'video'}
                    onChange={() => setInputType('video')}
                  />
                  <span className="ml-2">Use Seed Video</span>
                </label>
                <label className="inline-flex items-center">
                  <input
                    type="radio"
                    className="form-radio"
                    name="inputType"
                    checked={inputType === 'niche'}
                    onChange={() => setInputType('niche')}
                  />
                  <span className="ml-2">Use Niche</span>
                </label>
              </div>

              {inputType === 'video' ? (
                <div>
                  <label htmlFor="video_url" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    YouTube Video URL
                  </label>
                  <input
                    type="text"
                    id="video_url"
                    name="video_url"
                    placeholder="e.g., https://www.youtube.com/watch?v=example123"
                    className="input-field w-full"
                    value={formData.video_url}
                    onChange={handleChange}
                    required={inputType === 'video'}
                  />
                  <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                    Enter the URL of a successful YouTube video to use as inspiration
                  </p>
                </div>
              ) : (
                <div>
                  <label htmlFor="niche" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    YouTube Niche
                  </label>
                  <input
                    type="text"
                    id="niche"
                    name="niche"
                    placeholder="e.g., mobile gaming, cooking tutorials, fitness"
                    className="input-field w-full"
                    value={formData.niche}
                    onChange={handleChange}
                    required={inputType === 'niche'}
                  />
                  <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                    Enter a niche to analyze for YouTube channel opportunities
                  </p>
                </div>
              )}

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
                <div>
                  <label htmlFor="analysisDepth" className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Analysis Depth
                  </label>
                  <select
                    id="analysisDepth"
                    name="analysisDepth"
                    className="select-field w-full md:w-1/3"
                    value={formData.analysisDepth}
                    onChange={handleChange}
                  >
                    <option value="Quick">Quick (Basic Analysis)</option>
                    <option value="Standard">Standard (Recommended)</option>
                    <option value="Deep">Deep (Comprehensive Analysis)</option>
                  </select>
                  <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                    Select analysis depth - deeper analysis takes longer but provides more detailed results
                  </p>
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
    </div>
    // </MainLayout>
  );
}
