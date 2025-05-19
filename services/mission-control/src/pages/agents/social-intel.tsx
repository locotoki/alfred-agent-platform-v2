import { useState, useEffect } from 'react';
import MainLayout from '../../components/layout/MainLayout';
import Link from 'next/link';
import { useQuery } from 'react-query';
import { format } from 'date-fns';

// Mock function to get agent status - would be replaced with real API call
const getAgentStatus = async () => {
  return {
    status: 'online',
    version: '1.0.0',
    health: 100,
    uptime: '3h 42m',
    resources: {
      cpu: 38,
      memory: 32
    },
    supported_intents: [
      'TREND_ANALYSIS',
      'SOCIAL_MONITOR',
      'SENTIMENT_ANALYSIS'
    ]
  };
};

// Mock function to get recent tasks - would be replaced with real API call
const getRecentTasks = async () => {
  return [
    { id: 't-83921', time: '12:05', intent: 'TREND_ANALYSIS', status: 'completed', duration: '2.3s' },
    { id: 't-83915', time: '11:30', intent: 'TREND_ANALYSIS', status: 'completed', duration: '3.1s' },
    { id: 't-83901', time: '10:15', intent: 'SOCIAL_MONITOR', status: 'completed', duration: '1.8s' },
    { id: 't-83890', time: '09:30', intent: 'SENTIMENT_ANALYSIS', status: 'completed', duration: '2.5s' }
  ];
};

// Mock function to get API metrics - would be replaced with real API call
const getApiMetrics = async () => {
  return [
    { endpoint: '/niche-scout', calls_per_5min: 3, avg_response: '2.1s', errors: 0 },
    { endpoint: '/seed-to-blueprint', calls_per_5min: 2, avg_response: '3.2s', errors: 0 },
    { endpoint: '/force-analyze', calls_per_5min: 1, avg_response: '0.8s', errors: 0 },
    { endpoint: '/status', calls_per_5min: 12, avg_response: '0.1s', errors: 0 }
  ];
};

export default function SocialIntelligenceAgent() {
  // Agent Status Query
  const { data: agentStatus, isLoading: loadingStatus } = useQuery(
    'agentStatus',
    getAgentStatus,
    { refetchInterval: 5000 }
  );

  // Recent Tasks Query
  const { data: recentTasks, isLoading: loadingTasks } = useQuery(
    'recentTasks',
    getRecentTasks,
    { refetchInterval: 10000 }
  );

  // API Metrics Query
  const { data: apiMetrics, isLoading: loadingMetrics } = useQuery(
    'apiMetrics',
    getApiMetrics,
    { refetchInterval: 10000 }
  );

  return (
    <MainLayout title="Social Intelligence Agent">
      <div className="space-y-6">
        <div className="pb-5 border-b border-gray-200 dark:border-gray-700 mb-6">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Social Intelligence Agent
          </h1>
        </div>

        {/* Agent Status Card */}
        <div className="card p-6">
          <h2 className="text-lg font-semibold mb-4">Agent Status</h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
            <div className="space-y-4">
              <div className="flex justify-between">
                <span className="text-gray-600 dark:text-gray-400">Status:</span>
                <span className="flex items-center text-success-600 dark:text-success-400">
                  <span className="h-2.5 w-2.5 rounded-full bg-success-600 dark:bg-success-400 mr-1.5"></span>
                  {loadingStatus ? 'Loading...' : agentStatus?.status.toUpperCase() || 'ONLINE'}
                </span>
              </div>

              <div className="flex justify-between">
                <span className="text-gray-600 dark:text-gray-400">Health:</span>
                <span>{loadingStatus ? 'Loading...' : `${agentStatus?.health || 100}%`}</span>
              </div>
            </div>

            <div className="space-y-4">
              <div className="flex justify-between">
                <span className="text-gray-600 dark:text-gray-400">Version:</span>
                <span>{loadingStatus ? 'Loading...' : agentStatus?.version || '1.0.0'}</span>
              </div>

              <div className="flex justify-between">
                <span className="text-gray-600 dark:text-gray-400">Uptime:</span>
                <span>{loadingStatus ? 'Loading...' : agentStatus?.uptime || '3h 42m'}</span>
              </div>
            </div>
          </div>

          <div className="mb-6">
            <h3 className="text-md font-medium mb-3">System Resources:</h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <div className="flex justify-between mb-1">
                  <span className="text-sm text-gray-600 dark:text-gray-400">CPU:</span>
                  <span className="text-sm">{loadingStatus ? 'Loading...' : `${agentStatus?.resources.cpu || 38}%`}</span>
                </div>
                <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5">
                  <div
                    className="bg-primary-600 h-2.5 rounded-full"
                    style={{ width: `${loadingStatus ? 0 : agentStatus?.resources.cpu || 38}%` }}
                  ></div>
                </div>
              </div>

              <div>
                <div className="flex justify-between mb-1">
                  <span className="text-sm text-gray-600 dark:text-gray-400">Memory:</span>
                  <span className="text-sm">{loadingStatus ? 'Loading...' : `${agentStatus?.resources.memory || 32}%`}</span>
                </div>
                <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5">
                  <div
                    className="bg-primary-600 h-2.5 rounded-full"
                    style={{ width: `${loadingStatus ? 0 : agentStatus?.resources.memory || 32}%` }}
                  ></div>
                </div>
              </div>
            </div>
          </div>

          <div>
            <h3 className="text-md font-medium mb-3">Supported Intents:</h3>
            <div className="flex flex-wrap gap-2">
              {loadingStatus ? (
                <div>Loading...</div>
              ) : (
                (agentStatus?.supported_intents || ['TREND_ANALYSIS', 'SOCIAL_MONITOR', 'SENTIMENT_ANALYSIS']).map((intent, index) => (
                  <span key={index} className="px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-200">
                    {intent}
                  </span>
                ))
              )}
            </div>
          </div>
        </div>

        {/* Workflows Card */}
        <div className="card p-6">
          <h2 className="text-lg font-semibold mb-4">Workflows</h2>

          <div className="flex flex-wrap gap-4">
            <Link
              href="/workflows/niche-scout"
              className="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
            >
              Niche-Scout
            </Link>

            <Link
              href="/workflows/seed-to-blueprint"
              className="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
            >
              Seed-to-Blueprint
            </Link>

            <button className="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700">
              + New Workflow
            </button>
          </div>
        </div>

        {/* Recent Tasks Card */}
        <div className="card p-6">
          <h2 className="text-lg font-semibold mb-4">Recent Tasks</h2>

          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Time</th>
                  <th>Task ID</th>
                  <th>Intent</th>
                  <th>Status</th>
                  <th>Duration</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                {loadingTasks ? (
                  <tr>
                    <td colSpan={5} className="text-center py-4">Loading...</td>
                  </tr>
                ) : (
                  (recentTasks || []).map((task, index) => (
                    <tr key={index}>
                      <td>{task.time}</td>
                      <td>{task.id}</td>
                      <td>{task.intent}</td>
                      <td>
                        {task.status === 'completed' && (
                          <span className="status-completed">✓ Complete</span>
                        )}
                        {task.status === 'running' && (
                          <span className="status-pending">⟳ Running</span>
                        )}
                        {task.status === 'error' && (
                          <span className="status-error">✗ Error</span>
                        )}
                      </td>
                      <td>{task.duration}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* API Metrics Card */}
        <div className="card p-6">
          <h2 className="text-lg font-semibold mb-4">API Metrics</h2>

          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Endpoint</th>
                  <th>Calls/5min</th>
                  <th>Avg Response</th>
                  <th>Errors</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                {loadingMetrics ? (
                  <tr>
                    <td colSpan={4} className="text-center py-4">Loading...</td>
                  </tr>
                ) : (
                  (apiMetrics || []).map((metric, index) => (
                    <tr key={index}>
                      <td>{metric.endpoint}</td>
                      <td>{metric.calls_per_5min}</td>
                      <td>{metric.avg_response}</td>
                      <td>
                        <span className={metric.errors > 0 ? "text-danger-600" : "text-success-600"}>
                          {metric.errors}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </MainLayout>
  );
}
