import React, { useState, useEffect } from 'react';
import YouTubeApiTest from '@/components/workflows/YouTubeApiTest';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
// Direct imports using relative paths to work in both local and container environments
import { FadeIn } from '../components/ui/animations/FadeIn';
import { GradientButton } from '../components/ui/buttons/GradientButton';
import NicheScoutVisualizer from '../components/visualizations/NicheScoutVisualizer';
import { Lightbulb, TrendingUp, BarChart3, Zap } from 'lucide-react';

/**
 * Enhanced YouTube Test Results page with visualization
 */
const YouTubeTestOnly: React.FC = () => {
  const [activeTab, setActiveTab] = useState('overview');
  const [results, setResults] = useState<any>(null);

  // Listen for niche scout results
  useEffect(() => {
    const handleResultsMessage = (event: CustomEvent) => {
      if (event.detail && event.detail.type === 'nicheScoutResults') {
        setResults(event.detail.data);
      }
    };

    // Add event listener
    window.addEventListener('nicheScoutResults' as any, handleResultsMessage as any);

    // Cleanup
    return () => {
      window.removeEventListener('nicheScoutResults' as any, handleResultsMessage as any);
    };
  }, []);

  // Get from YouTubeApiTest component if available
  const updateResults = (newResults: any) => {
    setResults(newResults);
  };

  return (
    <div className="container py-6">
      <FadeIn direction="up" duration={400}>
        <div className="bg-gradient-primary text-white p-6 rounded-lg mb-8">
          <h1 className="text-3xl font-bold mb-2">YouTube Workflow Results</h1>
          <p className="text-white/80">
            View and analyze the results of your Niche Scout workflow
          </p>
        </div>
      </FadeIn>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2">
          <FadeIn direction="up" delay={100}>
            <Card className="shadow-md border-0 overflow-hidden">
              <CardHeader className="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-gray-800 dark:to-indigo-900/30 border-b pb-8">
                <CardTitle className="text-gradient-primary text-2xl">
                  Niche Scout Analysis
                </CardTitle>
                <CardDescription>
                  Discover high-potential YouTube niches with detailed opportunity scoring
                </CardDescription>
                
                <Tabs value={activeTab} onValueChange={setActiveTab} className="mt-4">
                  <TabsList>
                    <TabsTrigger value="overview" className="flex items-center">
                      <Lightbulb className="h-4 w-4 mr-2" />
                      Overview
                    </TabsTrigger>
                    <TabsTrigger value="visualization" className="flex items-center">
                      <BarChart3 className="h-4 w-4 mr-2" />
                      Visualization
                    </TabsTrigger>
                    <TabsTrigger value="data" className="flex items-center">
                      <TrendingUp className="h-4 w-4 mr-2" />
                      Raw Data
                    </TabsTrigger>
                  </TabsList>
                </Tabs>
              </CardHeader>
              
              <CardContent className="p-0">
                <TabsContent value="overview" className="p-4 mt-0">
                  <FadeIn direction="up">
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                      <Card className="bg-blue-50 dark:bg-blue-900/10 border-0">
                        <CardContent className="pt-6">
                          <div className="flex items-center">
                            <div className="bg-blue-500 p-2 rounded-lg text-white mr-4">
                              <BarChart3 className="h-5 w-5" />
                            </div>
                            <div>
                              <div className="text-sm text-blue-600 dark:text-blue-400 font-medium">
                                Total Niches
                              </div>
                              <div className="text-2xl font-bold">
                                {results ? results.trending_niches?.length || 0 : '--'}
                              </div>
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                      
                      <Card className="bg-purple-50 dark:bg-purple-900/10 border-0">
                        <CardContent className="pt-6">
                          <div className="flex items-center">
                            <div className="bg-purple-500 p-2 rounded-lg text-white mr-4">
                              <TrendingUp className="h-5 w-5" />
                            </div>
                            <div>
                              <div className="text-sm text-purple-600 dark:text-purple-400 font-medium">
                                Top Opportunity
                              </div>
                              <div className="text-2xl font-bold">
                                {results ? Math.round(results.top_niches?.[0]?.score || 0) : '--'}
                              </div>
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                      
                      <Card className="bg-green-50 dark:bg-green-900/10 border-0">
                        <CardContent className="pt-6">
                          <div className="flex items-center">
                            <div className="bg-green-500 p-2 rounded-lg text-white mr-4">
                              <Zap className="h-5 w-5" />
                            </div>
                            <div>
                              <div className="text-sm text-green-600 dark:text-green-400 font-medium">
                                Processing Time
                              </div>
                              <div className="text-2xl font-bold">
                                {results ? `${results.actual_processing_time?.toFixed(1)}s` : '--'}
                              </div>
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                    </div>
                    
                    {results ? (
                      <div className="space-y-6">
                        <div>
                          <h3 className="text-lg font-medium mb-3">Top Niches</h3>
                          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            {results.top_niches?.slice(0, 4).map((niche: any, idx: number) => (
                              <div key={idx} className="p-4 border rounded-lg hover:shadow-md transition-shadow">
                                <div className="font-medium text-blue-600 dark:text-blue-400">
                                  {niche.query}
                                </div>
                                <div className="mt-2 grid grid-cols-2 gap-x-4 gap-y-1 text-sm">
                                  <div>Score: <span className="font-medium">{Math.round(niche.score)}</span></div>
                                  <div>Views: <span className="font-medium">{niche.view_sum.toLocaleString()}</span></div>
                                  {niche.competition_level && (
                                    <div>Competition: <span className="font-medium">{niche.competition_level}</span></div>
                                  )}
                                  {niche.shorts_friendly !== undefined && (
                                    <div>Shorts: <span className="font-medium">{niche.shorts_friendly ? 'Yes' : 'No'}</span></div>
                                  )}
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                        
                        <div>
                          <h3 className="text-lg font-medium mb-3">Analysis Summary</h3>
                          <p className="text-gray-600 dark:text-gray-400">
                            The analysis identified {results.trending_niches?.length} potential niches, 
                            with the highest opportunity score of {Math.round(results.top_niches?.[0]?.score || 0)}.
                            {results.top_niches?.[0]?.shorts_friendly && 
                              " The top opportunity is suitable for YouTube Shorts format."}
                          </p>
                        </div>
                        
                        <div className="flex justify-end">
                          <GradientButton 
                            variant="primary" 
                            onClick={() => setActiveTab('visualization')}
                            iconAfter={<BarChart3 className="h-4 w-4 ml-1" />}
                          >
                            View Visualization
                          </GradientButton>
                        </div>
                      </div>
                    ) : (
                      <div className="flex flex-col items-center justify-center py-12 text-gray-500 dark:text-gray-400">
                        <div className="text-center mb-4">
                          <p className="text-lg font-medium mb-2">No results available</p>
                          <p className="text-sm">Run a Niche Scout analysis to see results here</p>
                        </div>
                      </div>
                    )}
                  </FadeIn>
                </TabsContent>
                
                <TabsContent value="visualization" className="mt-0">
                  <FadeIn direction="up">
                    {results ? (
                      <NicheScoutVisualizer 
                        data={results} 
                        darkMode={document.documentElement.classList.contains('dark')}
                      />
                    ) : (
                      <div className="flex flex-col items-center justify-center py-12 text-gray-500 dark:text-gray-400 p-4">
                        <div className="text-center mb-4">
                          <p className="text-lg font-medium mb-2">No visualization available</p>
                          <p className="text-sm">Run a Niche Scout analysis to see visualizations</p>
                        </div>
                      </div>
                    )}
                  </FadeIn>
                </TabsContent>
                
                <TabsContent value="data" className="p-4 mt-0">
                  <FadeIn direction="up">
                    <div className="overflow-auto">
                      <pre className="p-4 bg-gray-100 dark:bg-gray-800 rounded-lg text-xs max-h-[600px] overflow-auto">
                        {results ? JSON.stringify(results, null, 2) : 'No data available'}
                      </pre>
                    </div>
                  </FadeIn>
                </TabsContent>
              </CardContent>
            </Card>
          </FadeIn>
        </div>
        
        <div>
          <FadeIn direction="up" delay={200}>
            <YouTubeApiTest onResultsUpdate={updateResults} />
          </FadeIn>
        </div>
      </div>
    </div>
  );
};

export default YouTubeTestOnly;