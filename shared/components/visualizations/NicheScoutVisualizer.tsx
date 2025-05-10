import React, { useState } from 'react';
import {
  ScatterChart,
  Scatter,
  XAxis,
  YAxis,
  ZAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend
} from 'recharts';
import { Share2, TrendingUp, Search, Plus, BarChart3 } from 'lucide-react';

interface NicheData {
  query: string;
  view_sum: number;
  engagement: number;
  score: number;
  videos?: string[];
  top_channels?: Array<{name: string, subs: number}>;
  rsv?: number;
  growth_rate?: number;
  competition_level?: string;
  shorts_friendly?: boolean;
  view_rank?: number;
  rsv_rank?: number;
  niche?: number;
  x?: number;
  y?: number;
}

interface NicheScoutResult {
  run_date: string;
  trending_niches: NicheData[];
  top_niches: NicheData[];
  visualization_url?: string;
  actual_cost?: number;
  actual_processing_time?: number;
  status?: string;
}

interface NicheScoutVisualizerProps {
  data: NicheScoutResult;
  className?: string;
  darkMode?: boolean;
}

export const NicheScoutVisualizer: React.FC<NicheScoutVisualizerProps> = ({
  data,
  className = '',
  darkMode = false
}) => {
  const [selectedTab, setSelectedTab] = useState<'scatter'|'top'|'trending'>('scatter');
  const [selectedNiche, setSelectedNiche] = useState<NicheData | null>(null);
  
  if (!data || !data.trending_niches || !data.top_niches) {
    return (
      <div className="flex items-center justify-center p-8 text-gray-500 bg-gray-50 dark:bg-gray-800 dark:text-gray-400 rounded-lg">
        No data available to visualize
      </div>
    );
  }
  
  // Prepare scatter plot data
  const scatterData = data.trending_niches
    .filter(niche => typeof niche.x === 'number' && typeof niche.y === 'number')
    .map(niche => ({
      ...niche,
      z: Math.sqrt(niche.score || 1), // Size based on score
      fillColor: getColorByNiche(niche.niche || 0)
    }));
  
  // Get color based on niche group
  function getColorByNiche(nicheGroup: number): string {
    const colors = [
      '#3b82f6', // blue
      '#8b5cf6', // purple
      '#10b981', // green
      '#f59e0b', // amber
      '#ef4444'  // red
    ];
    
    return colors[nicheGroup % colors.length];
  }
  
  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload as NicheData;
      return (
        <div className="p-3 bg-white dark:bg-gray-800 shadow-lg rounded-lg border border-gray-200 dark:border-gray-700">
          <p className="font-medium text-gray-900 dark:text-white">{data.query}</p>
          <p className="text-sm text-gray-600 dark:text-gray-300">Score: {Math.round(data.score)}</p>
          <p className="text-sm text-gray-600 dark:text-gray-300">Views: {data.view_sum.toLocaleString()}</p>
          {data.competition_level && (
            <p className="text-sm text-gray-600 dark:text-gray-300">
              Competition: {data.competition_level}
            </p>
          )}
          {data.shorts_friendly && (
            <p className="text-sm text-blue-600 dark:text-blue-400">Shorts-friendly ✓</p>
          )}
        </div>
      );
    }
    return null;
  };
  
  return (
    <div className={`bg-white dark:bg-gray-800 rounded-lg overflow-hidden ${className}`}>
      {/* Tabs */}
      <div className="flex border-b border-gray-200 dark:border-gray-700">
        <button 
          className={`flex items-center px-4 py-3 text-sm font-medium ${
            selectedTab === 'scatter'
              ? 'text-blue-600 dark:text-blue-400 border-b-2 border-blue-500'
              : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
          }`}
          onClick={() => setSelectedTab('scatter')}
        >
          <BarChart3 className="h-4 w-4 mr-2" />
          Opportunity Map
        </button>
        <button 
          className={`flex items-center px-4 py-3 text-sm font-medium ${
            selectedTab === 'top'
              ? 'text-blue-600 dark:text-blue-400 border-b-2 border-blue-500'
              : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
          }`}
          onClick={() => setSelectedTab('top')}
        >
          <TrendingUp className="h-4 w-4 mr-2" />
          Top Opportunities
        </button>
        <button 
          className={`flex items-center px-4 py-3 text-sm font-medium ${
            selectedTab === 'trending'
              ? 'text-blue-600 dark:text-blue-400 border-b-2 border-blue-500'
              : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
          }`}
          onClick={() => setSelectedTab('trending')}
        >
          <Search className="h-4 w-4 mr-2" />
          Trending Niches
        </button>
      </div>
      
      {/* Main Visualization Content */}
      <div className="p-4">
        {selectedTab === 'scatter' && (
          <div className="space-y-4">
            <div className="text-sm text-gray-600 dark:text-gray-400 mb-2">
              This map visualizes niche opportunities based on supply and demand.
              Larger bubbles indicate higher opportunity score.
            </div>
            
            <div className="h-80 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <ScatterChart
                  margin={{ top: 20, right: 20, bottom: 20, left: 20 }}
                >
                  <CartesianGrid strokeDasharray="3 3" stroke={darkMode ? '#374151' : '#e5e7eb'} />
                  <XAxis 
                    type="number" 
                    dataKey="x" 
                    name="Supply" 
                    tick={{fill: darkMode ? '#9ca3af' : '#6b7280'}}
                    label={{ 
                      value: 'Supply', 
                      position: 'bottom',
                      fill: darkMode ? '#e5e7eb' : '#4b5563'
                    }}
                  />
                  <YAxis 
                    type="number" 
                    dataKey="y" 
                    name="Demand" 
                    tick={{fill: darkMode ? '#9ca3af' : '#6b7280'}}
                    label={{ 
                      value: 'Demand', 
                      angle: -90, 
                      position: 'left',
                      fill: darkMode ? '#e5e7eb' : '#4b5563'
                    }}
                  />
                  <ZAxis 
                    type="number" 
                    dataKey="z" 
                    range={[20, 200]} 
                    name="Score" 
                  />
                  <Tooltip content={<CustomTooltip />} />
                  <Legend />
                  <Scatter 
                    name="Niche Opportunities" 
                    data={scatterData} 
                    fill="#3b82f6"
                    fillOpacity={0.8}
                    strokeOpacity={0.9}
                    stroke={darkMode ? '#93c5fd' : '#2563eb'}
                    strokeWidth={1}
                  />
                </ScatterChart>
              </ResponsiveContainer>
            </div>
          </div>
        )}
        
        {selectedTab === 'top' && (
          <div className="space-y-4">
            <div className="text-sm text-gray-600 dark:text-gray-400 mb-2">
              These are the highest-opportunity niches based on our proprietary scoring algorithm.
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {data.top_niches.slice(0, 10).map((niche, index) => (
                <div 
                  key={index}
                  className="p-4 rounded-lg border border-gray-200 dark:border-gray-700 hover:bg-blue-50 dark:hover:bg-blue-900/20 transition-all duration-150"
                  onClick={() => setSelectedNiche(niche)}
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <div className="flex items-center">
                        <div 
                          className="h-6 w-6 rounded-full mr-2 flex items-center justify-center text-xs text-white"
                          style={{ background: getColorByNiche(niche.niche || 0) }}
                        >
                          {index + 1}
                        </div>
                        <h3 className="font-medium text-gray-900 dark:text-white">{niche.query}</h3>
                      </div>
                      <div className="mt-2 text-sm grid grid-cols-2 gap-x-4 gap-y-1">
                        <div className="text-gray-600 dark:text-gray-400">Score: <span className="font-medium text-gray-900 dark:text-white">{Math.round(niche.score)}</span></div>
                        <div className="text-gray-600 dark:text-gray-400">Views: <span className="font-medium text-gray-900 dark:text-white">{niche.view_sum.toLocaleString()}</span></div>
                        {niche.competition_level && (
                          <div className="text-gray-600 dark:text-gray-400">Competition: <span className="font-medium text-gray-900 dark:text-white">{niche.competition_level}</span></div>
                        )}
                        {niche.shorts_friendly && (
                          <div className="text-green-600 dark:text-green-400">Shorts-friendly ✓</div>
                        )}
                      </div>
                    </div>
                    <div 
                      className={`text-xs px-2 py-1 rounded-full ${
                        niche.competition_level === 'Low' 
                          ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                          : niche.competition_level === 'Medium'
                            ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300'
                            : 'bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300'
                      }`}
                    >
                      {niche.shorts_friendly ? 'Shorts' : 'Standard'}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
        
        {selectedTab === 'trending' && (
          <div className="space-y-4">
            <div className="text-sm text-gray-600 dark:text-gray-400 mb-2">
              These are the currently trending topics based on recent view patterns.
            </div>
            
            <div className="overflow-auto">
              <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                <thead className="bg-gray-50 dark:bg-gray-800">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Query</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Views</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Score</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Competition</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Type</th>
                  </tr>
                </thead>
                <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                  {data.trending_niches.slice(0, 15).map((niche, index) => (
                    <tr 
                      key={index}
                      className="hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer transition-colors duration-150"
                      onClick={() => setSelectedNiche(niche)}
                    >
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                          <div className="text-sm font-medium text-gray-900 dark:text-white">{niche.query}</div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900 dark:text-white">{niche.view_sum.toLocaleString()}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900 dark:text-white">{Math.round(niche.score)}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${
                          niche.competition_level === 'Low' 
                            ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300'
                            : niche.competition_level === 'Medium'
                              ? 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300'
                              : 'bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300'
                        }`}>
                          {niche.competition_level}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {niche.shorts_friendly ? (
                          <span className="px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300">
                            Shorts
                          </span>
                        ) : (
                          <span className="px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300">
                            Standard
                          </span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>
      
      {/* Footer with metadata */}
      <div className="px-4 py-3 bg-gray-50 dark:bg-gray-900/50 border-t border-gray-200 dark:border-gray-700 text-xs text-gray-500 dark:text-gray-400">
        <div className="flex justify-between items-center">
          <div>
            Analysis run: {new Date(data.run_date).toLocaleString()}
          </div>
          <div className="flex items-center">
            {data.actual_processing_time && (
              <span className="mr-4">Processing time: {data.actual_processing_time.toFixed(2)}s</span>
            )}
            <button className="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 flex items-center">
              <Share2 className="h-3 w-3 mr-1" />
              Share
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default NicheScoutVisualizer;