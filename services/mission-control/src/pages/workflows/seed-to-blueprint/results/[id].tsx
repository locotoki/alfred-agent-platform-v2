import { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import MainLayout from '../../../../components/layout/MainLayout';
import { getWorkflowResult } from '../../../../services/youtube-workflows';
import { BlueprintResult } from '../../../../types/youtube-workflows';

export default function SeedToBlueprintResults() {
  const router = useRouter();
  const { id } = router.query;
  
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [results, setResults] = useState<BlueprintResult | null>(null);
  const [activeTab, setActiveTab] = useState('blueprint');

  useEffect(() => {
    async function fetchResults() {
      if (!id) return;
      
      try {
        setIsLoading(true);
        console.log(`Fetching Seed-to-Blueprint results for ID: ${id}`);
        
        // Introduce a small delay for UX so loading state is visible
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        const data = await getWorkflowResult(id as string, 'seed-to-blueprint');
        
        if (!data) {
          throw new Error('No data returned from the server');
        }
        
        console.log(`Successfully fetched Seed-to-Blueprint results for ID: ${id}`);
        setResults(data as BlueprintResult);
      } catch (err) {
        console.error(`Error fetching Seed-to-Blueprint results: ${err instanceof Error ? err.message : 'Unknown error'}`);
        setError(err instanceof Error ? err.message : 'An unexpected error occurred');
      } finally {
        setIsLoading(false);
      }
    }

    fetchResults();
  }, [id]);

  return (
    <MainLayout title="Seed-to-Blueprint Results">
      <div className="space-y-6">
        <div className="pb-5 border-b border-gray-200 dark:border-gray-700 mb-6">
          <div className="flex items-center justify-between">
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
              CHANNEL BLUEPRINT
            </h1>
            <button 
              onClick={() => router.push('/workflows/seed-to-blueprint')}
              className="btn-secondary"
            >
              New Blueprint
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
              onClick={() => router.push('/workflows/seed-to-blueprint')}
              className="mt-2 text-red-600 dark:text-red-400 underline"
            >
              Return to Seed-to-Blueprint
            </button>
          </div>
        ) : results ? (
          <>
            {/* Seed Video Info */}
            <div className="card p-6">
              <h2 className="text-xl font-bold mb-4">Seed Information</h2>
              <div className="flex flex-col md:flex-row md:justify-between">
                <div className="mb-4 md:mb-0">
                  <p className="text-sm text-gray-500 dark:text-gray-400">Run Date</p>
                  <p className="text-lg font-medium">{new Date(results.run_date).toLocaleString()}</p>
                </div>
                <div className="mb-4 md:mb-0">
                  <p className="text-sm text-gray-500 dark:text-gray-400">Seed URL</p>
                  <a href={results.seed_url} target="_blank" rel="noopener noreferrer" className="text-lg font-medium text-blue-600 dark:text-blue-400 hover:underline">{results.seed_url}</a>
                </div>
                <div>
                  <p className="text-sm text-gray-500 dark:text-gray-400">Seed Title</p>
                  <p className="text-lg font-medium">{results.seed_data?.title || 'N/A'}</p>
                </div>
              </div>
            </div>

            {/* Tabs */}
            <div className="border-b border-gray-200 dark:border-gray-700">
              <nav className="-mb-px flex space-x-8 overflow-x-auto">
                <button
                  className={`${
                    activeTab === 'blueprint'
                      ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
                  } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
                  onClick={() => setActiveTab('blueprint')}
                >
                  Channel Blueprint
                </button>
                <button
                  className={`${
                    activeTab === 'competitors'
                      ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
                  } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
                  onClick={() => setActiveTab('competitors')}
                >
                  Top Competitors
                </button>
                <button
                  className={`${
                    activeTab === 'gapAnalysis'
                      ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
                  } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
                  onClick={() => setActiveTab('gapAnalysis')}
                >
                  Gap Analysis
                </button>
                <button
                  className={`${
                    activeTab === 'aiTips'
                      ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
                  } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
                  onClick={() => setActiveTab('aiTips')}
                >
                  AI Production Tips
                </button>
              </nav>
            </div>

            {/* Content based on active tab */}
            <div className="mt-6">
              {activeTab === 'blueprint' && (
                <div className="space-y-6">
                  {/* Positioning */}
                  <div className="card p-6">
                    <h2 className="text-xl font-bold mb-4">Channel Positioning</h2>
                    <p className="text-gray-700 dark:text-gray-300">
                      {results.blueprint.positioning}
                    </p>
                  </div>

                  {/* Content Pillars */}
                  <div className="card p-6">
                    <h2 className="text-xl font-bold mb-4">Content Pillars</h2>
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                      {results.blueprint.content_pillars.map((pillar, index) => (
                        <div key={index} className="bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg p-4 border border-blue-100 dark:border-blue-800">
                          <h3 className="font-bold text-lg mb-2 text-blue-700 dark:text-blue-300">
                            Pillar {index + 1}
                          </h3>
                          <p className="text-gray-800 dark:text-gray-200">{pillar}</p>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Format Mix */}
                  <div className="card p-6">
                    <h2 className="text-xl font-bold mb-4">Format Mix</h2>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      {Object.entries(results.blueprint.format_mix).map(([format, percentage], index) => (
                        <div key={index} className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 shadow-sm">
                          <h3 className="font-bold text-lg mb-2 capitalize">{format.replace('_', ' ')}</h3>
                          <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-4">
                            <div
                              className="bg-blue-600 dark:bg-blue-500 h-4 rounded-full"
                              style={{ width: `${(percentage as number) * 100}%` }}
                            ></div>
                          </div>
                          <p className="text-right mt-1 text-gray-600 dark:text-gray-400">
                            {((percentage as number) * 100).toFixed(0)}%
                          </p>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Content Roadmap */}
                  <div className="card p-6">
                    <h2 className="text-xl font-bold mb-4">30-Day Content Roadmap</h2>
                    <div className="space-y-6">
                      {Object.entries(results.blueprint.roadmap).map(([week, content], index) => (
                        <div key={index}>
                          <h3 className="font-bold text-md mb-2 text-gray-700 dark:text-gray-300">{week}</h3>
                          <ul className="list-disc ml-5 space-y-1">
                            {content.map((item, idx) => (
                              <li key={idx} className="text-gray-700 dark:text-gray-300">{item}</li>
                            ))}
                          </ul>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* COPPA Checklist */}
                  <div className="card p-6">
                    <h2 className="text-xl font-bold mb-4">COPPA Compliance Checklist</h2>
                    <div className="space-y-2">
                      {results.blueprint.coppa_checklist.map((item, index) => (
                        <div key={index} className="flex items-start">
                          <div className={`flex-shrink-0 h-5 w-5 rounded-full flex items-center justify-center mt-0.5 ${
                            item.status === 'Required' 
                              ? 'bg-red-100 text-red-500 dark:bg-red-900/30 dark:text-red-400' 
                              : 'bg-yellow-100 text-yellow-500 dark:bg-yellow-900/30 dark:text-yellow-400'
                          }`}>
                            {item.status === 'Required' ? '!' : '?'}
                          </div>
                          <div className="ml-3">
                            <p className="text-gray-700 dark:text-gray-300">{item.item}</p>
                            <p className="text-sm text-gray-500 dark:text-gray-400">{item.status}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {activeTab === 'competitors' && (
                <div className="card p-6">
                  <h2 className="text-xl font-bold mb-4">Top Competitor Channels</h2>
                  <div className="overflow-x-auto">
                    <table className="table">
                      <thead>
                        <tr>
                          <th>Rank</th>
                          <th>Channel</th>
                          <th>Subscribers</th>
                          <th>Total Views</th>
                          <th>Videos</th>
                          <th>Recent Uploads</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                        {results.top_channels.map((channel, index) => (
                          <tr key={index}>
                            <td>{index + 1}</td>
                            <td>{channel.channel_name}</td>
                            <td>{channel.subscribers.toLocaleString()}</td>
                            <td>{channel.total_views.toLocaleString()}</td>
                            <td>{channel.video_count}</td>
                            <td>{channel.recent_upload_count}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {activeTab === 'gapAnalysis' && (
                <div className="card p-6">
                  <h2 className="text-xl font-bold mb-4">Content Gap Analysis</h2>
                  <p className="text-gray-600 dark:text-gray-400 mb-4">
                    Topics with high opportunity scores represent content gaps that competitors aren't fully covering.
                  </p>
                  <div className="overflow-x-auto">
                    <table className="table">
                      <thead>
                        <tr>
                          <th>Keyword</th>
                          <th>Seed Coverage</th>
                          <th>Competitor Coverage</th>
                          <th>Opportunity Score</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                        {results.gap_analysis.map((gap, index) => (
                          <tr key={index}>
                            <td>{gap.keyword}</td>
                            <td>{(gap.seed_coverage * 100).toFixed(0)}%</td>
                            <td>
                              {Object.entries(gap.competitor_coverage).length > 0 
                                ? Object.entries(gap.competitor_coverage)
                                  .filter(([_, coverage]) => coverage > 0)
                                  .map(([channel, _]) => channel)
                                  .join(', ') || 'None'
                                : 'Not analyzed'}
                            </td>
                            <td>
                              <div className="flex items-center">
                                <div className="w-24 bg-gray-200 dark:bg-gray-700 rounded-full h-2 mr-2">
                                  <div
                                    className="bg-blue-600 dark:bg-blue-500 h-2 rounded-full"
                                    style={{ width: `${gap.opportunity_score * 100}%` }}
                                  ></div>
                                </div>
                                <span>{(gap.opportunity_score * 100).toFixed(0)}%</span>
                              </div>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {activeTab === 'aiTips' && (
                <div className="card p-6">
                  <h2 className="text-xl font-bold mb-4">AI Production Tips</h2>
                  <div className="space-y-4">
                    {results.blueprint.ai_production_tips.map((tip, index) => (
                      <div key={index} className="flex items-start">
                        <div className="flex-shrink-0 h-6 w-6 rounded-full bg-blue-100 dark:bg-blue-900/30 text-blue-500 dark:text-blue-400 flex items-center justify-center mt-0.5">
                          {index + 1}
                        </div>
                        <div className="ml-3">
                          <p className="text-gray-700 dark:text-gray-300">{tip}</p>
                        </div>
                      </div>
                    ))}
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
                    a.download = `blueprint-results-${new Date().toISOString().split('T')[0]}.json`;
                    document.body.appendChild(a);
                    a.click();
                    // Clean up
                    document.body.removeChild(a);
                    URL.revokeObjectURL(url);
                  }}
                  className="btn-secondary"
                >
                  Download JSON
                </button>
                <a
                  href={results.blueprint_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="btn-primary"
                >
                  Download Package
                </a>
              </div>
            </div>
          </>
        ) : null}
      </div>
    </MainLayout>
  );
}