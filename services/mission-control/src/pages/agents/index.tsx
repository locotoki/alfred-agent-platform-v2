import { useState } from 'react';
import Head from 'next/head';
import Link from 'next/link';
import MainLayout from '../../components/layout/MainLayout';
import { FiPlus, FiSearch, FiFilter } from 'react-icons/fi';

export default function Agents() {
  const [searchQuery, setSearchQuery] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');

  // Mock data for agents
  const agents = [
    {
      id: 'agent-1',
      name: 'Alfred Bot',
      description: 'General purpose assistant for task management and coordination',
      status: 'active',
      lastActive: '2023-05-05T10:30:00',
      tasks: 3,
      cpu: 12,
    },
    {
      id: 'agent-2',
      name: 'Social Intel',
      description: 'Social media monitoring and analysis',
      status: 'active',
      lastActive: '2023-05-05T11:20:00',
      tasks: 5,
      cpu: 38,
    },
    {
      id: 'agent-3',
      name: 'Financial-Tax',
      description: 'Financial calculations and tax assistance',
      status: 'active',
      lastActive: '2023-05-05T09:45:00',
      tasks: 2,
      cpu: 8,
    },
    {
      id: 'agent-4',
      name: 'Legal',
      description: 'Legal document analysis and compliance checking',
      status: 'active',
      lastActive: '2023-05-05T10:15:00',
      tasks: 2,
      cpu: 5,
    },
    {
      id: 'agent-5',
      name: 'Market Research',
      description: 'Web scraping and market analysis',
      status: 'idle',
      lastActive: '2023-05-04T16:30:00',
      tasks: 0,
      cpu: 0,
    },
    {
      id: 'agent-6',
      name: 'Customer Support',
      description: 'Automated response system for customer inquiries',
      status: 'maintenance',
      lastActive: '2023-05-03T14:20:00',
      tasks: 0,
      cpu: 0,
    }
  ];

  // Filter agents based on search query and status filter
  const filteredAgents = agents.filter(agent => {
    const matchesSearch = agent.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
                          agent.description.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter = filterStatus === 'all' || agent.status === filterStatus;
    return matchesSearch && matchesFilter;
  });

  return (
    <MainLayout title="Agents">
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Agent Management</h1>
          <button className="btn-primary flex items-center">
            <FiPlus className="mr-2" /> Create Agent
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
                placeholder="Search agents..."
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
                <option value="active">Active</option>
                <option value="idle">Idle</option>
                <option value="maintenance">Maintenance</option>
              </select>
            </div>
          </div>

          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Description</th>
                  <th>Status</th>
                  <th>Tasks</th>
                  <th>CPU Usage</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                {filteredAgents.length > 0 ? (
                  filteredAgents.map((agent) => (
                    <tr key={agent.id}>
                      <td>
                        <Link href={`/agents/${agent.id}`} className="font-medium text-primary-600 dark:text-primary-400 hover:underline">
                          {agent.name}
                        </Link>
                      </td>
                      <td className="text-sm text-gray-600 dark:text-gray-400">{agent.description}</td>
                      <td>
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium
                          ${agent.status === 'active' ? 'bg-success-100 text-success-800 dark:bg-success-900 dark:text-success-200' : 
                            agent.status === 'idle' ? 'bg-warning-100 text-warning-800 dark:bg-warning-900 dark:text-warning-200' :
                            'bg-danger-100 text-danger-800 dark:bg-danger-900 dark:text-danger-200'}`}>
                          {agent.status.toUpperCase()}
                        </span>
                      </td>
                      <td>{agent.tasks}</td>
                      <td>
                        <div className="flex items-center">
                          <div className="w-24 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                            <div
                              className={`h-2 rounded-full ${
                                agent.cpu > 80 ? 'bg-danger-500' : 
                                agent.cpu > 50 ? 'bg-warning-500' : 'bg-success-500'
                              }`}
                              style={{ width: `${agent.cpu}%` }}
                            ></div>
                          </div>
                          <span className="ml-2 text-xs">{agent.cpu}%</span>
                        </div>
                      </td>
                      <td>
                        <div className="flex space-x-2">
                          <button className="btn-sm">Restart</button>
                          <button className="btn-sm">Details</button>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={6} className="text-center py-4">
                      No agents match your search criteria
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