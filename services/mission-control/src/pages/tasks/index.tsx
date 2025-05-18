import { useState } from 'react';
import Head from 'next/head';
import Link from 'next/link';
import MainLayout from '../../components/layout/MainLayout';
import { FiPlus, FiSearch, FiFilter, FiClock, FiCheckCircle, FiAlertCircle } from 'react-icons/fi';

export default function Tasks() {
  const [searchQuery, setSearchQuery] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');

  // Mock data for tasks
  const tasks = [
    {
      id: 'task-1',
      name: 'Social media trend analysis',
      agent: 'Social Intel',
      status: 'running',
      progress: 65,
      startedAt: '2023-05-05T09:30:00',
      dueAt: '2023-05-05T12:30:00',
      priority: 'high',
    },
    {
      id: 'task-2',
      name: 'Competitor website monitoring',
      agent: 'Alfred Bot',
      status: 'running',
      progress: 32,
      startedAt: '2023-05-05T10:15:00',
      dueAt: '2023-05-05T14:15:00',
      priority: 'medium',
    },
    {
      id: 'task-3',
      name: 'Monthly finance report',
      agent: 'Financial-Tax',
      status: 'running',
      progress: 78,
      startedAt: '2023-05-05T08:00:00',
      dueAt: '2023-05-05T16:00:00',
      priority: 'high',
    },
    {
      id: 'task-4',
      name: 'Legal document review',
      agent: 'Legal',
      status: 'running',
      progress: 45,
      startedAt: '2023-05-05T09:00:00',
      dueAt: '2023-05-06T09:00:00',
      priority: 'medium',
    },
    {
      id: 'task-5',
      name: 'Customer feedback analysis',
      agent: 'Social Intel',
      status: 'queued',
      progress: 0,
      startedAt: null,
      dueAt: '2023-05-05T17:00:00',
      priority: 'low',
    },
    {
      id: 'task-6',
      name: 'Security audit',
      agent: 'Alfred Bot',
      status: 'completed',
      progress: 100,
      startedAt: '2023-05-04T14:00:00',
      dueAt: '2023-05-04T18:00:00',
      priority: 'high',
    },
    {
      id: 'task-7',
      name: 'Quarterly tax calculations',
      agent: 'Financial-Tax',
      status: 'failed',
      progress: 87,
      startedAt: '2023-05-04T11:30:00',
      dueAt: '2023-05-04T17:30:00',
      priority: 'high',
    }
  ];

  // Helper to format dates
  const formatDate = (dateString) => {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleString();
  };

  // Filter tasks based on search query and status filter
  const filteredTasks = tasks.filter(task => {
    const matchesSearch = task.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                          task.agent.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter = filterStatus === 'all' || task.status === filterStatus;
    return matchesSearch && matchesFilter;
  });

  return (
    <MainLayout title="Tasks">
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Task Management</h1>
          <button className="btn-primary flex items-center">
            <FiPlus className="mr-2" /> Create Task
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
                placeholder="Search tasks..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <div className="flex items-center space-x-2">
              <FiFilter className="text-gray-500 dark:text-gray-400" />
              <select
                className="input"
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
              >
                <option value="all">All Statuses</option>
                <option value="running">Running</option>
                <option value="queued">Queued</option>
                <option value="completed">Completed</option>
                <option value="failed">Failed</option>
              </select>
            </div>
          </div>

          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Agent</th>
                  <th>Status</th>
                  <th>Progress</th>
                  <th>Started</th>
                  <th>Due</th>
                  <th>Priority</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                {filteredTasks.length > 0 ? (
                  filteredTasks.map((task) => (
                    <tr key={task.id}>
                      <td>
                        <Link href={`/tasks/${task.id}`} className="font-medium text-primary-600 dark:text-primary-400 hover:underline">
                          {task.name}
                        </Link>
                      </td>
                      <td>{task.agent}</td>
                      <td>
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
                          ${task.status === 'running' ? 'bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-200' :
                            task.status === 'queued' ? 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200' :
                            task.status === 'completed' ? 'bg-success-100 text-success-800 dark:bg-success-900 dark:text-success-200' :
                            'bg-danger-100 text-danger-800 dark:bg-danger-900 dark:text-danger-200'}`}>
                          {task.status === 'running' && <FiClock className="mr-1" />}
                          {task.status === 'completed' && <FiCheckCircle className="mr-1" />}
                          {task.status === 'failed' && <FiAlertCircle className="mr-1" />}
                          {task.status.toUpperCase()}
                        </span>
                      </td>
                      <td>
                        <div className="flex items-center">
                          <div className="w-24 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                            <div
                              className={`h-2 rounded-full ${
                                task.status === 'failed' ? 'bg-danger-500' :
                                task.status === 'completed' ? 'bg-success-500' : 'bg-primary-500'
                              }`}
                              style={{ width: `${task.progress}%` }}
                            ></div>
                          </div>
                          <span className="ml-2 text-xs">{task.progress}%</span>
                        </div>
                      </td>
                      <td className="text-sm">{formatDate(task.startedAt)}</td>
                      <td className="text-sm">{formatDate(task.dueAt)}</td>
                      <td>
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
                          ${task.priority === 'high' ? 'bg-danger-100 text-danger-800 dark:bg-danger-900 dark:text-danger-200' :
                            task.priority === 'medium' ? 'bg-warning-100 text-warning-800 dark:bg-warning-900 dark:text-warning-200' :
                            'bg-success-100 text-success-800 dark:bg-success-900 dark:text-success-200'}`}>
                          {task.priority.toUpperCase()}
                        </span>
                      </td>
                      <td>
                        <div className="flex space-x-2">
                          {task.status === 'running' && <button className="btn-sm">Pause</button>}
                          {task.status === 'queued' && <button className="btn-sm">Start</button>}
                          {task.status === 'failed' && <button className="btn-sm">Retry</button>}
                          <button className="btn-sm">Details</button>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={8} className="text-center py-4">
                      No tasks match your search criteria
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </MainLayout>
  );
}
