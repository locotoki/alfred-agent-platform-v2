import { useEffect, useState } from 'react';
import MainLayout from '../components/layout/MainLayout';
import { useQuery } from 'react-query';
import { getWorkflowHistory } from '../services/youtube-workflows';
import { format } from 'date-fns';
import { FiActivity, FiAlertTriangle, FiArrowUp, FiArrowDown, FiCpu, FiDatabase, FiServer, FiUsers, FiRefreshCw, FiClock, FiCheckCircle, FiXCircle } from 'react-icons/fi';
import StatsCard from '../components/ui/StatsCard';

// Mock data for charts
const generateChartData = () => {
  const data = [];
  for (let i = 0; i < 24; i++) {
    data.push({
      hour: i,
      cpu: Math.floor(Math.random() * 40) + 10,
      memory: Math.floor(Math.random() * 30) + 20,
      tasks: Math.floor(Math.random() * 10)
    });
  }
  return data;
};

export default function Dashboard() {
  // Fetch workflow history
  const { data: workflowHistory, isLoading } = useQuery('workflowHistory', getWorkflowHistory, {
    refetchInterval: 30000, // Refresh every 30 seconds
  });

  const [systemMetrics, setSystemMetrics] = useState({
    cpuUsage: 27,
    memoryUsage: 42,
    activeTasks: 12,
    successRate: 98.5,
    errorRate: 1.5,
    totalAgents: 8,
    activeAgents: 6
  });

  const chartData = generateChartData();

  return (
    <MainLayout title="Dashboard">
      <div className="space-y-8">
        {/* Welcome Section with Summary */}
        <div className="dashboard-card p-6 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-gray-800 dark:to-indigo-900/30 border-b border-blue-100 dark:border-indigo-800/30">
          <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
            <div>
              <h1 className="text-2xl md:text-3xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
                Welcome to Mission Control
              </h1>
              <p className="mt-1 text-gray-600 dark:text-gray-400">
                Platform overview and real-time monitoring
              </p>
            </div>
            <button className="btn-primary py-2 px-4 text-white flex items-center shadow-md hover:shadow-lg transition-all duration-200 ease-in-out">
              <FiRefreshCw className="mr-2" /> Refresh Dashboard
            </button>
          </div>
        </div>

        {/* System Overview Stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {/* CPU Usage */}
          <StatsCard
            title="CPU Usage"
            value={`${systemMetrics.cpuUsage}%`}
            icon={FiCpu}
            trend={{
              value: "2.1% from last hour",
              isPositive: false
            }}
            colorClass="bg-blue-500"
          />

          {/* Memory Usage */}
          <StatsCard
            title="Memory Usage"
            value={`${systemMetrics.memoryUsage}%`}
            icon={FiDatabase}
            trend={{
              value: "1.3% from last hour",
              isPositive: true
            }}
            colorClass="bg-indigo-500"
          />

          {/* Active Tasks */}
          <StatsCard
            title="Active Tasks"
            value={systemMetrics.activeTasks}
            icon={FiActivity}
            trend={{
              value: "3 more than yesterday",
              isPositive: true
            }}
            colorClass="bg-green-500"
          />

          {/* Success Rate */}
          <StatsCard
            title="Success Rate"
            value={`${systemMetrics.successRate}%`}
            icon={FiCheckCircle}
            trend={{
              value: "0.5% improvement",
              isPositive: true
            }}
            colorClass="bg-purple-500"
          />
        </div>

        {/* Middle Row - Agent Status and Activity */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Agent Status */}
          <div className="dashboard-card col-span-1 p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-semibold">Agent Status</h2>
              <span className="badge-gradient-primary">
                {systemMetrics.activeAgents} / {systemMetrics.totalAgents} Online
              </span>
            </div>

            <div className="space-y-4">
              <div className="border dark:border-gray-700 rounded-lg p-4 transition-all hover:border-primary-500 dark:hover:border-primary-500">
                <div className="flex justify-between items-center mb-2">
                  <h3 className="font-medium flex items-center">
                    <div className="mr-2 h-2 w-2 rounded-full bg-success-500 pulse-dot"></div>
                    Alfred Bot
                  </h3>
                  <span className="badge-gradient-success">ONLINE</span>
                </div>
                <div className="mt-2 flex flex-col space-y-2">
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-gray-600 dark:text-gray-400">CPU:</span>
                    <div className="flex items-center w-24">
                      <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5 mr-2">
                        <div className="bg-primary-500 h-1.5 rounded-full" style={{ width: '12%' }}></div>
                      </div>
                      <span>12%</span>
                    </div>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-gray-600 dark:text-gray-400">Memory:</span>
                    <div className="flex items-center w-24">
                      <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5 mr-2">
                        <div className="bg-primary-500 h-1.5 rounded-full" style={{ width: '8%' }}></div>
                      </div>
                      <span>8%</span>
                    </div>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-gray-600 dark:text-gray-400">Tasks:</span>
                    <span className="font-medium">3 running</span>
                  </div>
                </div>
              </div>

              <div className="border dark:border-gray-700 rounded-lg p-4 transition-all hover:border-primary-500 dark:hover:border-primary-500">
                <div className="flex justify-between items-center mb-2">
                  <h3 className="font-medium flex items-center">
                    <div className="mr-2 h-2 w-2 rounded-full bg-success-500 pulse-dot"></div>
                    Social Intel
                  </h3>
                  <span className="badge-gradient-success">ONLINE</span>
                </div>
                <div className="mt-2 flex flex-col space-y-2">
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-gray-600 dark:text-gray-400">CPU:</span>
                    <div className="flex items-center w-24">
                      <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5 mr-2">
                        <div className="bg-warning-500 h-1.5 rounded-full" style={{ width: '38%' }}></div>
                      </div>
                      <span>38%</span>
                    </div>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-gray-600 dark:text-gray-400">Memory:</span>
                    <div className="flex items-center w-24">
                      <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5 mr-2">
                        <div className="bg-primary-500 h-1.5 rounded-full" style={{ width: '25%' }}></div>
                      </div>
                      <span>25%</span>
                    </div>
                  </div>
                  <div className="flex justify-between items-center text-sm">
                    <span className="text-gray-600 dark:text-gray-400">Tasks:</span>
                    <span className="font-medium">5 running</span>
                  </div>
                </div>
              </div>

              <button className="btn-sm text-primary-600 dark:text-primary-400 hover:underline font-medium w-full text-center">
                View All Agents →
              </button>
            </div>
          </div>

          {/* System Activity Feed */}
          <div className="dashboard-card col-span-1 lg:col-span-2 p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-semibold">Activity Feed</h2>
              <button className="btn-sm flex items-center text-primary-600 dark:text-primary-400">
                <FiRefreshCw className="mr-1 h-3 w-3" /> Refresh
              </button>
            </div>

            <div className="space-y-4">
              <div className="relative">
                <div className="absolute top-0 left-5 h-full w-0.5 bg-gradient-to-b from-green-500 via-blue-500 to-red-500 dark:from-green-400 dark:via-blue-400 dark:to-red-400"></div>
                {/* Activity item 1 */}
                <div className="relative flex items-start mb-6 group">
                  <span className="h-10 w-10 flex items-center justify-center rounded-full bg-gradient-to-br from-green-400 to-green-600 dark:from-green-500 dark:to-green-700 text-white shadow-md z-10 transform transition-transform group-hover:scale-110">
                    <FiCheckCircle className="h-5 w-5" />
                  </span>
                  <div className="ml-4 bg-white dark:bg-gray-800 p-4 rounded-lg shadow-sm border border-gray-100 dark:border-gray-700 w-full transform transition-all group-hover:-translate-y-1 group-hover:shadow-md">
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
                      <p className="font-medium text-gray-900 dark:text-white flex items-center">
                        <span className="bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent">Task Completed</span>
                        <span className="ml-2 inline-block w-2 h-2 bg-green-500 rounded-full pulse-dot"></span>
                      </p>
                      <span className="text-sm text-gray-500 dark:text-gray-400 bg-gray-100 dark:bg-gray-700 px-2 py-0.5 rounded-full mt-1 sm:mt-0">10 min ago</span>
                    </div>
                    <p className="mt-2 text-sm text-gray-600 dark:text-gray-300">
                      Social Intelligence agent completed "Niche Scout" workflow
                    </p>
                    <div className="mt-3 flex items-center">
                      <span className="badge-gradient-success mr-2 shadow-sm">Success</span>
                      <span className="text-xs text-gray-500 dark:text-gray-400 flex items-center">
                        <svg className="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                          <path d="M5 3a2 2 0 00-2 2v2a2 2 0 002 2h2a2 2 0 002-2V5a2 2 0 00-2-2H5zM5 11a2 2 0 00-2 2v2a2 2 0 002 2h2a2 2 0 002-2v-2a2 2 0 00-2-2H5zM11 5a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V5zM11 13a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z"></path>
                        </svg>
                        Processed 125 data points
                      </span>
                    </div>
                  </div>
                </div>

                {/* Activity item 2 */}
                <div className="relative flex items-start mb-6 group">
                  <span className="h-10 w-10 flex items-center justify-center rounded-full bg-gradient-to-br from-blue-400 to-blue-600 dark:from-blue-500 dark:to-blue-700 text-white shadow-md z-10 transform transition-transform group-hover:scale-110">
                    <FiClock className="h-5 w-5" />
                  </span>
                  <div className="ml-4 bg-white dark:bg-gray-800 p-4 rounded-lg shadow-sm border border-gray-100 dark:border-gray-700 w-full transform transition-all group-hover:-translate-y-1 group-hover:shadow-md">
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
                      <p className="font-medium text-gray-900 dark:text-white flex items-center">
                        <span className="bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">Task Started</span>
                        <span className="ml-2 inline-block w-2 h-2 bg-blue-500 rounded-full pulse-dot"></span>
                      </p>
                      <span className="text-sm text-gray-500 dark:text-gray-400 bg-gray-100 dark:bg-gray-700 px-2 py-0.5 rounded-full mt-1 sm:mt-0">25 min ago</span>
                    </div>
                    <p className="mt-2 text-sm text-gray-600 dark:text-gray-300">
                      Financial-Tax agent started "Quarterly Tax Report" workflow
                    </p>
                    <div className="mt-3 flex items-center">
                      <span className="badge-gradient-primary mr-2 shadow-sm">In Progress</span>
                      <span className="text-xs text-gray-500 dark:text-gray-400 flex items-center">
                        <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                        </svg>
                        Estimated completion: 35 min
                      </span>
                    </div>
                  </div>
                </div>

                {/* Activity item 3 */}
                <div className="relative flex items-start group">
                  <span className="h-10 w-10 flex items-center justify-center rounded-full bg-gradient-to-br from-red-400 to-red-600 dark:from-red-500 dark:to-red-700 text-white shadow-md z-10 transform transition-transform group-hover:scale-110">
                    <FiXCircle className="h-5 w-5" />
                  </span>
                  <div className="ml-4 bg-white dark:bg-gray-800 p-4 rounded-lg shadow-sm border border-gray-100 dark:border-gray-700 w-full transform transition-all group-hover:-translate-y-1 group-hover:shadow-md">
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
                      <p className="font-medium text-gray-900 dark:text-white flex items-center">
                        <span className="bg-gradient-to-r from-red-600 to-rose-600 bg-clip-text text-transparent">Error Detected</span>
                        <span className="ml-2 inline-block w-2 h-2 bg-red-500 rounded-full pulse-dot"></span>
                      </p>
                      <span className="text-sm text-gray-500 dark:text-gray-400 bg-gray-100 dark:bg-gray-700 px-2 py-0.5 rounded-full mt-1 sm:mt-0">45 min ago</span>
                    </div>
                    <p className="mt-2 text-sm text-gray-600 dark:text-gray-300">
                      Legal Compliance agent encountered an error processing documents
                    </p>
                    <div className="mt-3 flex items-center">
                      <span className="badge-gradient-danger mr-2 shadow-sm">Error</span>
                      <span className="text-xs text-gray-500 dark:text-gray-400 flex items-center">
                        <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
                        </svg>
                        Auto-retry scheduled
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              <button className="btn-primary w-full py-2 text-white font-medium flex items-center justify-center mt-4 hover:shadow-lg transition-all">
                <span>View All Activity</span>
                <svg className="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14 5l7 7m0 0l-7 7m7-7H3"></path>
                </svg>
              </button>
            </div>
          </div>
        </div>

        {/* Task Distribution & Performance */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Task Distribution */}
          <div className="dashboard-card p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-semibold bg-gradient-to-r from-blue-600 to-cyan-600 bg-clip-text text-transparent">Current Tasks by Type</h2>
              <span className="text-sm font-medium text-gray-600 dark:text-gray-400 bg-gray-100 dark:bg-gray-700 px-3 py-1 rounded-full">
                12 Total Tasks
              </span>
            </div>
            <div className="h-60 flex items-center justify-center">
              <div className="grid grid-cols-2 gap-5 w-full">
                <div className="flex flex-col items-center justify-center p-5 rounded-lg bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/30 dark:to-blue-800/30 border border-blue-200 dark:border-blue-800 shadow-sm hover:shadow-md transition-all duration-200 transform hover:-translate-y-1">
                  <div className="w-16 h-16 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 flex items-center justify-center mb-3 shadow-lg">
                    <span className="text-2xl font-bold text-white">5</span>
                  </div>
                  <span className="text-sm font-medium text-gray-800 dark:text-gray-200">Data Analysis</span>
                  <div className="mt-2 w-full bg-blue-200 dark:bg-blue-700 rounded-full h-1.5">
                    <div className="bg-blue-600 h-1.5 rounded-full" style={{ width: '42%' }}></div>
                  </div>
                  <span className="mt-1 text-xs text-gray-500 dark:text-gray-400">42% of tasks</span>
                </div>

                <div className="flex flex-col items-center justify-center p-5 rounded-lg bg-gradient-to-br from-purple-50 to-purple-100 dark:from-purple-900/30 dark:to-purple-800/30 border border-purple-200 dark:border-purple-800 shadow-sm hover:shadow-md transition-all duration-200 transform hover:-translate-y-1">
                  <div className="w-16 h-16 rounded-full bg-gradient-to-r from-purple-500 to-fuchsia-600 flex items-center justify-center mb-3 shadow-lg">
                    <span className="text-2xl font-bold text-white">3</span>
                  </div>
                  <span className="text-sm font-medium text-gray-800 dark:text-gray-200">Content Generation</span>
                  <div className="mt-2 w-full bg-purple-200 dark:bg-purple-700 rounded-full h-1.5">
                    <div className="bg-purple-600 h-1.5 rounded-full" style={{ width: '25%' }}></div>
                  </div>
                  <span className="mt-1 text-xs text-gray-500 dark:text-gray-400">25% of tasks</span>
                </div>

                <div className="flex flex-col items-center justify-center p-5 rounded-lg bg-gradient-to-br from-green-50 to-green-100 dark:from-green-900/30 dark:to-green-800/30 border border-green-200 dark:border-green-800 shadow-sm hover:shadow-md transition-all duration-200 transform hover:-translate-y-1">
                  <div className="w-16 h-16 rounded-full bg-gradient-to-r from-green-500 to-emerald-600 flex items-center justify-center mb-3 shadow-lg">
                    <span className="text-2xl font-bold text-white">2</span>
                  </div>
                  <span className="text-sm font-medium text-gray-800 dark:text-gray-200">Financial Analysis</span>
                  <div className="mt-2 w-full bg-green-200 dark:bg-green-700 rounded-full h-1.5">
                    <div className="bg-green-600 h-1.5 rounded-full" style={{ width: '17%' }}></div>
                  </div>
                  <span className="mt-1 text-xs text-gray-500 dark:text-gray-400">17% of tasks</span>
                </div>

                <div className="flex flex-col items-center justify-center p-5 rounded-lg bg-gradient-to-br from-yellow-50 to-yellow-100 dark:from-yellow-900/30 dark:to-yellow-800/30 border border-yellow-200 dark:border-yellow-800 shadow-sm hover:shadow-md transition-all duration-200 transform hover:-translate-y-1">
                  <div className="w-16 h-16 rounded-full bg-gradient-to-r from-yellow-500 to-amber-600 flex items-center justify-center mb-3 shadow-lg">
                    <span className="text-2xl font-bold text-white">2</span>
                  </div>
                  <span className="text-sm font-medium text-gray-800 dark:text-gray-200">Legal Compliance</span>
                  <div className="mt-2 w-full bg-yellow-200 dark:bg-yellow-700 rounded-full h-1.5">
                    <div className="bg-yellow-600 h-1.5 rounded-full" style={{ width: '17%' }}></div>
                  </div>
                  <span className="mt-1 text-xs text-gray-500 dark:text-gray-400">17% of tasks</span>
                </div>
              </div>
            </div>
          </div>

          {/* Performance Metrics */}
          <div className="dashboard-card p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-lg font-semibold bg-gradient-to-r from-purple-600 to-indigo-600 bg-clip-text text-transparent">Performance Overview</h2>
              <span className="px-3 py-1 bg-gradient-to-r from-green-500 to-emerald-600 text-white text-sm font-medium rounded-full shadow-sm">
                94% Health
              </span>
            </div>
            <div className="space-y-6">
              <div>
                <div className="flex justify-between mb-2">
                  <div>
                    <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Response Time</span>
                    <div className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">Average time to complete task requests</div>
                  </div>
                  <span className="text-sm font-medium inline-flex items-center px-2.5 py-0.5 rounded-full bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-300">
                    <svg className="w-3 h-3 mr-1 text-green-500" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd"></path>
                    </svg>
                    Excellent
                  </span>
                </div>
                <div className="w-full h-3 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div className="h-full rounded-full bg-gradient-to-r from-green-400 to-green-600" style={{ width: '92%' }}></div>
                </div>
              </div>

              <div>
                <div className="flex justify-between mb-2">
                  <div>
                    <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Task Completion Rate</span>
                    <div className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">Successfully completed tasks</div>
                  </div>
                  <span className="text-sm font-medium inline-flex items-center px-2.5 py-0.5 rounded-full bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-300">
                    <svg className="w-3 h-3 mr-1 text-green-500" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd"></path>
                    </svg>
                    Very Good
                  </span>
                </div>
                <div className="w-full h-3 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div className="h-full rounded-full bg-gradient-to-r from-green-400 to-blue-500" style={{ width: '88%' }}></div>
                </div>
              </div>

              <div>
                <div className="flex justify-between mb-2">
                  <div>
                    <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Resource Efficiency</span>
                    <div className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">Optimal resource utilization</div>
                  </div>
                  <span className="text-sm font-medium inline-flex items-center px-2.5 py-0.5 rounded-full bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-300">
                    Good
                  </span>
                </div>
                <div className="w-full h-3 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div className="h-full rounded-full bg-gradient-to-r from-blue-400 to-indigo-500" style={{ width: '76%' }}></div>
                </div>
              </div>

              <div>
                <div className="flex justify-between mb-2">
                  <div>
                    <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Error Handling</span>
                    <div className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">Recovery from failures</div>
                  </div>
                  <span className="text-sm font-medium inline-flex items-center px-2.5 py-0.5 rounded-full bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-300">
                    Improving
                  </span>
                </div>
                <div className="w-full h-3 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div className="h-full rounded-full bg-gradient-to-r from-yellow-400 to-orange-500" style={{ width: '65%' }}></div>
                </div>
              </div>

              <div className="pt-4 border-t border-gray-200 dark:border-gray-700 mt-4">
                <div className="flex items-center justify-between">
                  <div>
                    <span className="font-medium text-gray-700 dark:text-gray-300">Overall System Health</span>
                    <div className="flex items-center mt-1">
                      <span className="text-xl font-bold text-gray-900 dark:text-white">94%</span>
                      <span className="ml-2 flex items-center text-xs font-medium text-green-600">
                        <svg className="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 10l7-7m0 0l7 7m-7-7v18"></path>
                        </svg>
                        2.5% this week
                      </span>
                    </div>
                  </div>
                  <div className="w-16 h-16 rounded-full flex items-center justify-center bg-gradient-to-br from-green-400 to-blue-500 text-white font-bold text-xl shadow-lg">
                    94%
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </MainLayout>
  );
}
