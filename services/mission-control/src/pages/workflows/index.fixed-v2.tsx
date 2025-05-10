import React from 'react';
import Link from 'next/link';
import { useRouter } from 'next/router';
import MainLayout from '../../components/layout/MainLayout';
import { format } from 'date-fns';

export default function Workflows() {
  const router = useRouter();
  
  // Mock data for development
  const scheduledWorkflows = [
    {
      id: 'sched-1234',
      workflow_type: 'niche-scout',
      parameters: { query: 'gaming' },
      frequency: 'daily',
      next_run: new Date(Date.now() + 86400000).toISOString(),
      status: 'scheduled',
      created_at: new Date(Date.now() - 86400000).toISOString(),
      updated_at: new Date(Date.now() - 86400000).toISOString(),
      user_id: 'user-1'
    },
    {
      id: 'sched-2345',
      workflow_type: 'seed-to-blueprint',
      parameters: { niche: 'fitness' },
      frequency: 'weekly',
      next_run: new Date(Date.now() + 604800000).toISOString(),
      status: 'scheduled',
      created_at: new Date(Date.now() - 172800000).toISOString(),
      updated_at: new Date(Date.now() - 172800000).toISOString(),
      user_id: 'user-1'
    },
    {
      id: 'sched-3456',
      workflow_type: 'niche-scout',
      parameters: { query: 'cooking' },
      frequency: 'once',
      next_run: new Date(Date.now() + 259200000).toISOString(),
      status: 'scheduled',
      created_at: new Date(Date.now() - 86400000).toISOString(),
      updated_at: new Date(Date.now() - 86400000).toISOString(),
      user_id: 'user-1'
    }
  ];

  const workflowHistory = [
    {
      id: 'wf-1234',
      workflow_type: 'niche-scout',
      parameters: { query: 'gaming' },
      status: 'completed',
      started_at: new Date(Date.now() - 3600000).toISOString(),
      completed_at: new Date(Date.now() - 3540000).toISOString(),
      result_url: '/api/social-intel/workflow-result/wf-1234',
      user_id: 'user-1'
    },
    {
      id: 'wf-2345',
      workflow_type: 'seed-to-blueprint',
      parameters: { video_url: 'https://youtube.com/watch?v=example123' },
      status: 'completed',
      started_at: new Date(Date.now() - 7200000).toISOString(),
      completed_at: new Date(Date.now() - 7080000).toISOString(),
      result_url: '/api/social-intel/workflow-result/wf-2345',
      user_id: 'user-1'
    },
    {
      id: 'wf-3456',
      workflow_type: 'niche-scout',
      parameters: { query: 'cooking' },
      status: 'completed',
      started_at: new Date(Date.now() - 86400000).toISOString(),
      completed_at: new Date(Date.now() - 86340000).toISOString(),
      result_url: '/api/social-intel/workflow-result/wf-3456',
      user_id: 'user-1'
    },
    {
      id: 'wf-4567',
      workflow_type: 'seed-to-blueprint',
      parameters: { niche: 'fitness' },
      status: 'completed',
      started_at: new Date(Date.now() - 172800000).toISOString(),
      completed_at: new Date(Date.now() - 172740000).toISOString(),
      result_url: '/api/social-intel/workflow-result/wf-4567',
      user_id: 'user-1'
    }
  ];

  const renderWorkflowCard = (title, description, href) => (
    <div className="card p-6 h-full flex flex-col">
      <h2 className="text-xl font-bold mb-4">{title}</h2>
      <p className="text-gray-600 dark:text-gray-400 mb-4 flex-grow">
        {description}
      </p>
      <div className="text-sm text-gray-500 dark:text-gray-400 mb-4">
        <p>Last run: May 5, 2025</p>
        <p>Status: Available</p>
      </div>
      <Link 
        href={href}
        className="btn-primary text-center"
      >
        RUN WORKFLOW
      </Link>
    </div>
  );

  return (
    <MainLayout title="Workflows">
      <div className="space-y-6">
        <div className="pb-5 border-b border-gray-200 dark:border-gray-700 mb-6">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            YOUTUBE RESEARCH WORKFLOWS
          </h1>
        </div>

        {/* Workflow Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {renderWorkflowCard(
            "Niche-Scout",
            "Find trending YouTube niches with growth metrics",
            "/workflows/niche-scout"
          )}
          {renderWorkflowCard(
            "Seed-to-Blueprint",
            "Create channel strategy from seed video or niche",
            "/workflows/seed-to-blueprint"
          )}
        </div>

        {/* Scheduled Runs */}
        <div className="card p-4">
          <h2 className="text-lg font-semibold mb-4">Scheduled Runs</h2>
          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Time</th>
                  <th>Workflow</th>
                  <th>Parameters</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                {scheduledWorkflows.map((workflow, index) => (
                  <tr key={index}>
                    <td>{workflow.frequency}</td>
                    <td>{workflow.workflow_type === 'niche-scout' ? 'Niche-Scout' : 'Seed-to-Blueprint'}</td>
                    <td>
                      {Object.entries(workflow.parameters)
                        .filter(([_, value]) => value)
                        .map(([key, value]) => `${value}`)
                        .join(', ')}
                    </td>
                    <td><span className="status-scheduled">⏱ Scheduled</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Workflow History */}
        <div className="card p-4">
          <h2 className="text-lg font-semibold mb-4">Workflow History</h2>
          <div className="table-container">
            <table className="table">
              <thead>
                <tr>
                  <th>Time</th>
                  <th>Workflow</th>
                  <th>Parameters</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                {workflowHistory.map((workflow, index) => (
                  <tr key={index}>
                    <td>{format(new Date(workflow.started_at), 'MMM d')}</td>
                    <td>{workflow.workflow_type === 'niche-scout' ? 'Niche-Scout' : 'Seed-to-Blueprint'}</td>
                    <td>
                      {Object.entries(workflow.parameters)
                        .filter(([_, value]) => value)
                        .map(([key, value]) => `${value}`)
                        .join(', ')}
                    </td>
                    <td>
                      {workflow.status === 'completed' && (
                        <span className="status-completed">✓ Completed</span>
                      )}
                      {workflow.status === 'running' && (
                        <span className="status-pending">⟳ Running</span>
                      )}
                      {workflow.status === 'error' && (
                        <span className="status-error">✗ Error</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </MainLayout>
  );
}