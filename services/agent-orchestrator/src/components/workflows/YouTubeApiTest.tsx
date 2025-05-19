import React, { useState, useEffect } from 'react';
import { Loader2, RefreshCw } from 'lucide-react';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { runNicheScout } from '@/lib/youtube-service';
import { FEATURES } from '@/lib/api-config';
import { GradientButton } from '../ui/buttons/GradientButton';
import { FadeIn } from '../ui/animations/FadeIn';

interface YouTubeApiTestProps {
  onResultsUpdate?: (results: any) => void;
}

/**
 * A component to test YouTube API connectivity with enhanced UI
 */
const YouTubeApiTest: React.FC<YouTubeApiTestProps> = ({ onResultsUpdate }) => {
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<any>(null);
  const [lastResults, setLastResults] = useState<any[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [useMockData, setUseMockData] = useState(FEATURES.USE_MOCK_DATA);
  const [selectedTab, setSelectedTab] = useState('current');

  // Check for console logs with API results
  useEffect(() => {
    const originalConsoleLog = console.log;

    console.log = function(...args) {
      if (args[0] === 'Niche scout completed:' && args[1]) {
        // Store the result
        setLastResults(prev => {
          const newResults = [...prev];
          newResults.unshift(args[1]);
          return newResults.slice(0, 5); // Keep last 5 results
        });
      }
      originalConsoleLog.apply(console, args);
    };

    return () => {
      console.log = originalConsoleLog;
    };
  }, []);

  const handleTestApi = async () => {
    setLoading(true);
    setError(null);

    try {
      // Use the Kids & Family > Nursery Rhymes & Songs category from our taxonomy
      const result = await runNicheScout({
        category: 'kids',
        subcategory: 'kids.nursery',
        budget: 100,
        dataSources: {
          youtube: true,
          reddit: false,
          amazon: false,
          sentiment: false
        }
      });

      setResult(result);
      setLastResults(prev => {
        const newResults = [result, ...prev];
        return newResults.slice(0, 5); // Keep last 5 results
      });

      // Notify parent component if provided
      if (onResultsUpdate) {
        onResultsUpdate(result);
      }

      // Dispatch event for other components to listen to
      const resultEvent = new CustomEvent('nicheScoutResults', {
        detail: { type: 'nicheScoutResults', data: result }
      });
      window.dispatchEvent(resultEvent);

      console.log('YouTube API test result:', result);
    } catch (err) {
      console.error('YouTube API test error:', err);
      setError(err instanceof Error ? err.message : 'An unknown error occurred');
    } finally {
      setLoading(false);
    }
  };

  const renderResultContent = (resultData: any) => {
    if (!resultData) return null;

    return (
      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-4 p-4 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-gray-800/50 dark:to-indigo-900/20 rounded-lg">
          <div>
            <div className="text-sm font-medium text-muted-foreground">Run Date</div>
            <div className="font-medium">{new Date(resultData.run_date).toLocaleString()}</div>
          </div>
          <div>
            <div className="text-sm font-medium text-muted-foreground">Data Source</div>
            <div className="font-medium">{useMockData ? 'Mock Data' : 'Real YouTube API'}</div>
          </div>
        </div>

        <FadeIn direction="up" delay={100}>
          <div>
            <h3 className="text-sm font-medium mb-2 text-gradient-primary">Top Niches</h3>
            <ul className="space-y-2">
              {resultData.top_niches?.slice(0, 5).map((niche: any, index: number) => (
                <li key={index} className="text-sm p-2 bg-blue-50 dark:bg-blue-900/10 rounded-md">
                  <span className="font-medium text-blue-600 dark:text-blue-400">{niche.query}</span> -
                  Score: <span className="font-medium">{Math.round(niche.score)}</span>
                </li>
              ))}
            </ul>
          </div>
        </FadeIn>

        <FadeIn direction="up" delay={200}>
          <div>
            <h3 className="text-sm font-medium mb-2 text-gradient-secondary">Trending Niches</h3>
            <ul className="space-y-2">
              {resultData.trending_niches?.slice(0, 5).map((niche: any, index: number) => (
                <li key={index} className="text-sm p-2 bg-purple-50 dark:bg-purple-900/10 rounded-md">
                  <span className="font-medium text-purple-600 dark:text-purple-400">{niche.query}</span> -
                  Views: <span className="font-medium">{niche.view_sum.toLocaleString()}</span>
                </li>
              ))}
            </ul>
          </div>
        </FadeIn>

        {resultData.actual_processing_time && (
          <div className="text-sm text-muted-foreground mt-4 text-right">
            Processing time: {resultData.actual_processing_time.toFixed(2)}s
          </div>
        )}
      </div>
    );
  };

  return (
    <Card className="w-full shadow-md border-0 overflow-hidden">
      <CardHeader className="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-gray-800 dark:to-indigo-900/30">
        <CardTitle>Run Niche Scout</CardTitle>
        <CardDescription>
          Test the YouTube API with a sample query
        </CardDescription>
      </CardHeader>

      <CardContent className="p-4 pt-6">
        <Tabs value={selectedTab} onValueChange={setSelectedTab}>
          <TabsList className="mb-4">
            <TabsTrigger value="current">Current Test</TabsTrigger>
            <TabsTrigger value="history">Recent Results</TabsTrigger>
          </TabsList>

          <TabsContent value="current">
            {loading && (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="h-8 w-8 animate-spin text-primary" />
                <span className="ml-2">Testing API connection...</span>
              </div>
            )}

            {error && (
              <Alert variant="destructive" className="mb-4">
                <AlertTitle>Error</AlertTitle>
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}

            {result && !loading && renderResultContent(result)}

            {!result && !loading && !error && (
              <div className="flex flex-col items-center justify-center py-8 text-gray-500 dark:text-gray-400">
                <p className="mb-2">No test has been run yet</p>
                <p className="text-sm">Click the button below to test the YouTube API</p>
              </div>
            )}
          </TabsContent>

          <TabsContent value="history">
            {lastResults.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                <p>No previous results found</p>
                <p className="text-sm mt-2">Run a test to see results here</p>
              </div>
            ) : (
              <div className="space-y-6">
                {lastResults.map((historyResult, idx) => (
                  <div key={idx} className="border p-4 rounded-lg hover:shadow-md transition-shadow">
                    <h3 className="font-medium mb-2 text-gradient-primary">Result #{idx + 1}</h3>
                    {renderResultContent(historyResult)}
                  </div>
                ))}
              </div>
            )}
          </TabsContent>
        </Tabs>
      </CardContent>

      <CardFooter className="bg-gray-50 dark:bg-gray-900/50 border-t p-4">
        <div className="flex flex-col w-full gap-2">
          <GradientButton
            variant="primary"
            onClick={handleTestApi}
            disabled={loading}
            iconBefore={loading ? (
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
            ) : (
              <RefreshCw className="h-4 w-4 mr-2" />
            )}
            fullWidth
          >
            {loading ? "Running Analysis..." : "Run Niche Scout Analysis"}
          </GradientButton>
          <div className="text-xs text-center text-muted-foreground mt-2">
            Using {useMockData ? 'mock data' : 'real API'} • Kids &gt; Nursery Rhymes category
          </div>
        </div>
      </CardFooter>
    </Card>
  );
};

export default YouTubeApiTest;
