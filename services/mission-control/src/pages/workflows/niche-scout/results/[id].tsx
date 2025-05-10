import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import MainLayout from '../../../../components/layout/MainLayout';
import { getWorkflowResult } from '../../../../services/youtube-workflows';
import { NicheScoutResult } from '../../../../types/youtube-workflows';

export default function NicheScoutResults() {
  const router = useRouter();
  const { id } = router.query;
  
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [results, setResults] = useState<NicheScoutResult | null>(null);
  const [activeTab, setActiveTab] = useState('overview');

  useEffect(() => {
    async function fetchResults() {
      if (!id) return;
      
      try {
        setIsLoading(true);
        console.log(`Fetching Niche-Scout results for ID: ${id}`);
        
        // Introduce a small delay for UX so loading state is visible
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        const data = await getWorkflowResult(id as string, 'niche-scout');
        
        if (!data) {
          throw new Error('No data returned from the server');
        }
        
        console.log(`Successfully fetched Niche-Scout results for ID: ${id}`);
        setResults(data as NicheScoutResult);
      } catch (err) {
        console.error(`Error fetching Niche-Scout results: ${err instanceof Error ? err.message : 'Unknown error'}`);
        setError(err instanceof Error ? err.message : 'An unexpected error occurred');
      } finally {
        setIsLoading(false);
      }
    }

    fetchResults();
  }, [id]);

  // Sort niches by score for display
  const sortedNiches = results?.top_niches?.sort((a, b) => b.score - a.score) || [];

  return (
    <MainLayout title="Niche-Scout Results">
      <div className="space-y-6">
        <div className="pb-5 border-b border-gray-200 dark:border-gray-700 mb-6">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              NICHE-SCOUT RESULTS
            </h1>
            <button 
              onClick={() => router.push('/workflows/niche-scout')}
              className="btn-secondary"
            >
              New Search
            </button>
          </div>
        </div>

        {isLoading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-pulse flex flex-col items-center">
              <div className="h-12 w-12 rounded-full border-4 border-t-blue-500 border-b-blue-700 border-l-blue-500 border-r-blue-700 animate-spin"></div>
              <div className="mt-4 text-gray-600 dark:text-gray-400">Loading results...</div>
            </div>
          </div>
        ) : error ? (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-800 dark:text-red-200 p-4 rounded-md">
            <h3 className="font-bold">Error</h3>
            <p>{error}</p>
            <button 
              onClick={() => router.push('/workflows/niche-scout')}
              className="mt-2 text-red-600 dark:text-red-400 underline"
            >
              Return to Niche-Scout
            </button>
          </div>
        ) : results ? (
          <>
            {/* Tabs */}
            <div className="border-b border-gray-200 dark:border-gray-700">
              <nav className="-mb-px flex space-x-8">
                <button
                  className={`${
                    activeTab === 'overview'
                      ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
                  } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
                  onClick={() => setActiveTab('overview')}
                >
                  Overview
                </button>
                <button
                  className={`${
                    activeTab === 'trending'
                      ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
                  } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
                  onClick={() => setActiveTab('trending')}
                >
                  Trending Niches
                </button>
                <button
                  className={`${
                    activeTab === 'visualization'
                      ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
                  } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
                  onClick={() => setActiveTab('visualization')}
                >
                  Visualization
                </button>
              </nav>
            </div>

            {/* Content based on active tab */}
            <div className="mt-6">
              {activeTab === 'overview' && (
                <div className="space-y-6">
                  <div className="card p-6">
                    <h2 className="text-xl font-bold mb-4">Analysis Overview</h2>
                    <div className="flex flex-col md:flex-row md:justify-between">
                      <div className="mb-4 md:mb-0">
                        <p className="text-sm text-gray-500 dark:text-gray-400">Run Date</p>
                        <p className="text-lg font-medium">{new Date(results.run_date).toLocaleString()}</p>
                      </div>
                      <div className="mb-4 md:mb-0">
                        <p className="text-sm text-gray-500 dark:text-gray-400">Total Niches Analyzed</p>
                        <p className="text-lg font-medium">{results.trending_niches.length}</p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Top Opportunity</p>
                        <p className="text-lg font-medium">{sortedNiches[0]?.query || 'N/A'}</p>
                      </div>
                    </div>
                  </div>

                  <div className="card p-6">
                    <h2 className="text-xl font-bold mb-4">Top 5 Niches by Score</h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                      {sortedNiches.slice(0, 5).map((niche, index) => (
                        <div key={index} className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
                          <h3 className="font-bold text-lg mb-2">{niche.query}</h3>
                          <div className="space-y-2">
                            <div className="flex justify-between">
                              <span className="text-gray-600 dark:text-gray-400">Score:</span>
                              <span className="font-medium">{niche.score.toFixed(2)}</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-gray-600 dark:text-gray-400">Views:</span>
                              <span className="font-medium">{niche.view_sum.toLocaleString()}</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-gray-600 dark:text-gray-400">Trend Value:</span>
                              <span className="font-medium">{niche.rsv.toFixed(2)}</span>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="card p-6">
                    <h2 className="text-xl font-bold mb-4">Key Insights</h2>
                    <ul className="space-y-2 list-disc list-inside">
                      <li>Highest scoring niche is <strong>{sortedNiches[0]?.query || 'N/A'}</strong> with a score of {sortedNiches[0]?.score.toFixed(2) || 'N/A'}</li>
                      <li>Highest view count is {Math.max(...(results.trending_niches.map(n => n.view_sum) || [0])).toLocaleString()} views</li>
                      <li>Found {results.trending_niches.filter(n => n.rsv > 50).length} niches with above-average trend scores</li>
                      <li>Identified {new Set(results.trending_niches.map(n => n.niche)).size} distinct niche clusters</li>
                    </ul>
                  </div>
                </div>
              )}

              {activeTab === 'trending' && (
                <div className="card p-6">
                  <h2 className="text-xl font-bold mb-4">All Trending Niches</h2>
                  <div className="overflow-x-auto">
                    <table className="table">
                      <thead>
                        <tr>
                          <th>Rank</th>
                          <th>Niche</th>
                          <th>Score</th>
                          <th>Views</th>
                          <th>Trend Value</th>
                          <th>Cluster</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                        {sortedNiches.map((niche, index) => (
                          <tr key={index}>
                            <td>{index + 1}</td>
                            <td>{niche.query}</td>
                            <td>{niche.score.toFixed(2)}</td>
                            <td>{niche.view_sum.toLocaleString()}</td>
                            <td>{niche.rsv.toFixed(2)}</td>
                            <td>{niche.niche}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {activeTab === 'visualization' && (
                <div className="card p-6">
                  <h2 className="text-xl font-bold mb-4">Niche Visualization</h2>
                  <div className="bg-gray-100 dark:bg-gray-800 rounded-lg p-4 flex items-center justify-center h-80">
                    {results.visualization_url ? (
                      <img 
                        src={results.visualization_url} 
                        alt="Niche visualization" 
                        className="max-h-full max-w-full object-contain"
                      />
                    ) : (
                      <div className="text-center">
                        <div className="h-40 w-40 mx-auto">
                          <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
                            <g className="fill-blue-500 dark:fill-blue-400">
                              <circle cx="20" cy="20" r="8" />
                              <circle cx="60" cy="30" r="12" />
                              <circle cx="35" cy="55" r="10" />
                              <circle cx="70" cy="70" r="14" />
                              <circle cx="90" cy="40" r="6" />
                            </g>
                          </svg>
                        </div>
                        <p className="text-gray-600 dark:text-gray-400 mt-4">
                          Interactive visualization currently not available.
                          <br />
                          A scatter plot of niches would appear here, clustered by similarity.
                        </p>
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>

            <div className="flex justify-between mt-8">
              <button
                onClick={() => router.push('/workflows')}
                className="btn-secondary"
              >
                Back to Workflows
              </button>
              <div className="flex space-x-4">
                <button
                  onClick={() => {
                    // Create a JSON string from the results
                    const jsonStr = JSON.stringify(results, null, 2);
                    // Create a blob with the JSON data
                    const blob = new Blob([jsonStr], { type: 'application/json' });
                    // Create a URL for the blob
                    const url = URL.createObjectURL(blob);
                    // Create a link element
                    const a = document.createElement('a');
                    a.href = url;
                    a.download = `niche-scout-results-${new Date().toISOString().split('T')[0]}.json`;
                    document.body.appendChild(a);
                    a.click();
                    // Clean up
                    document.body.removeChild(a);
                    URL.revokeObjectURL(url);
                  }}
                  className="btn-secondary"
                >
                  Download Results
                </button>
                <button
                  onClick={() => router.push('/workflows/seed-to-blueprint')}
                  className="btn-primary"
                >
                  Create Blueprint
                </button>
              </div>
            </div>
          </>
        ) : null}
      </div>
    </MainLayout>
  );
}