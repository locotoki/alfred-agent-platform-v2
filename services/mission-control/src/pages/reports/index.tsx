import { useState } from 'react';
import Head from 'next/head';
import MainLayout from '../../components/layout/MainLayout';
import { FiDownload, FiSearch, FiFilter, FiBarChart2, FiPieChart, FiTrendingUp } from 'react-icons/fi';

export default function Reports() {
  const [searchQuery, setSearchQuery] = useState('');
  const [filterCategory, setFilterCategory] = useState('all');

  // Mock data for reports
  const reports = [
    {
      id: 'report-1',
      name: 'Monthly Performance Dashboard',
      description: 'Overview of all agent performance metrics for the past month',
      category: 'performance',
      createdAt: '2023-05-01T12:30:00',
      createdBy: 'System',
      format: 'dashboard',
      icon: FiBarChart2
    },
    {
      id: 'report-2',
      name: 'Task Completion Analysis',
      description: 'Detailed breakdown of task completion rates by agent',
      category: 'tasks',
      createdAt: '2023-05-03T09:15:00',
      createdBy: 'Admin',
      format: 'pdf',
      icon: FiPieChart
    },
    {
      id: 'report-3',
      name: 'Resource Utilization',
      description: 'CPU, memory, and network usage across all agents',
      category: 'performance',
      createdAt: '2023-05-04T14:20:00',
      createdBy: 'System',
      format: 'csv',
      icon: FiBarChart2
    },
    {
      id: 'report-4',
      name: 'Social Media Trends',
      description: 'Analysis of social media engagement and trends',
      category: 'analytics',
      createdAt: '2023-05-04T16:45:00',
      createdBy: 'Social Intel Agent',
      format: 'dashboard',
      icon: FiTrendingUp
    },
    {
      id: 'report-5',
      name: 'Financial Summary',
      description: 'Summary of financial transactions and calculations',
      category: 'finance',
      createdAt: '2023-05-02T11:30:00',
      createdBy: 'Financial-Tax Agent',
      format: 'pdf',
      icon: FiPieChart
    }
  ];

  // Helper to format dates
  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
  };

  // Filter reports based on search query and category filter
  const filteredReports = reports.filter(report => {
    const matchesSearch = report.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          report.description.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter = filterCategory === 'all' || report.category === filterCategory;
    return matchesSearch && matchesFilter;
  });

  return (
    <MainLayout title="Reports">
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Reports</h1>
          <button className="btn-primary flex items-center">
            <FiBarChart2 className="mr-2" /> Generate New Report
          </button>
        </div>

        <div className="card p-4">
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center space-y-4 sm:space-y-0 mb-4">
            <div className="relative w-full sm:w-64">
              <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <FiSearch className="text-gray-400" />
              </div>
              <input
                type="text"
                className="input pl-10 w-full"
                placeholder="Search reports..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <div className="flex items-center space-x-2">
              <FiFilter className="text-gray-500 dark:text-gray-400" />
              <select
                className="input"
                value={filterCategory}
                onChange={(e) => setFilterCategory(e.target.value)}
              >
                <option value="all">All Categories</option>
                <option value="performance">Performance</option>
                <option value="tasks">Tasks</option>
                <option value="analytics">Analytics</option>
                <option value="finance">Finance</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredReports.length > 0 ? (
              filteredReports.map((report) => (
                <div key={report.id} className="border dark:border-gray-700 rounded-lg overflow-hidden shadow-sm hover:shadow-md transition-shadow">
                  <div className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="flex-shrink-0 bg-primary-100 dark:bg-primary-900 rounded-lg p-3">
                        <report.icon className="h-6 w-6 text-primary-600 dark:text-primary-400" />
                      </div>
                      <span className="text-xs text-gray-500 dark:text-gray-400">
                        {formatDate(report.createdAt)}
                      </span>
                    </div>
                    <h3 className="mt-3 text-lg font-medium text-gray-900 dark:text-white">
                      {report.name}
                    </h3>
                    <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">
                      {report.description}
                    </p>
                    <div className="mt-4 flex items-center justify-between">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200">
                        {report.category.toUpperCase()}
                      </span>
                      <button className="flex items-center text-sm text-primary-600 dark:text-primary-400 hover:underline">
                        <FiDownload className="mr-1" /> Download
                      </button>
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <div className="col-span-full text-center py-8 text-gray-500 dark:text-gray-400">
                No reports match your search criteria
              </div>
            )}
          </div>
        </div>
      </div>
    </MainLayout>
  );
}
