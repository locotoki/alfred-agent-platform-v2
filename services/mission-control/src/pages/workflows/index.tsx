import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import { format } from 'date-fns';

// Layout and components
import MainLayout from '../../components/layout/MainLayout';
import WorkflowCard from '../../../components/workflows/WorkflowCard';
import StatusBadge from '../../../components/ui/StatusBadge';

// Services and types
import { getWorkflowHistory, getScheduledWorkflows } from '../../services/youtube-workflows';
import { WorkflowHistory, WorkflowSchedule } from '../../types/youtube-workflows';

export default function Workflows() {
  const router = useRouter();
  
  // State for workflow data
  const [scheduledWorkflows, setScheduledWorkflows] = useState<WorkflowSchedule[]>([]);
  const [workflowHistory, setWorkflowHistory] = useState<WorkflowHistory[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  // Fetch workflow data function
  const fetchWorkflowData = async () => {
    try {
      setIsLoading(true);
      setError(null);
      
      // Fetch both scheduled workflows and history in parallel
      const [historyData, scheduledData] = await Promise.all([
        getWorkflowHistory(),
        getScheduledWorkflows()
      ]);
      
      setWorkflowHistory(historyData);
      setScheduledWorkflows(scheduledData);
      
      console.log('Fetched workflow history:', historyData);
      console.log('Fetched scheduled workflows:', scheduledData);
    } catch (err) {
      console.error('Error fetching workflow data:', err);
      setError('Failed to load workflow data. Please try again later.');
    } finally {
      setIsLoading(false);
    }
  };
  
  // Fetch data on component mount
  useEffect(() => {
    fetchWorkflowData();
  }, []);

  return (
    <MainLayout title="Workflows">
      <div className="space-y-6">
        <div className="mb-6">
          <h1 className="heading-1">Youtube Research Workflows</h1>
        </div>

        {/* Available Workflows */}
        <section className="section">
          <h2 className="heading-2 mb-4">Available Workflows</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <WorkflowCard
              title="Niche-Scout"
              description="Find trending YouTube niches with growth metrics. Analyze view and engagement data to discover growth opportunities."
              href="/workflows/niche-scout"
            />
            <WorkflowCard
              title="Seed-to-Blueprint"
              description="Create a complete channel strategy from a seed video or niche keyword. Includes content pillars, format mix, and 30-day roadmap."
              href="/workflows/seed-to-blueprint"
              isNew={true}
            />
          </div>
        </section>

        {/* Error Message */}
        {error && (
          <div className="alert-error">
            <p>{error}</p>
          </div>
        )}

        {/* Loading State */}
        {isLoading ? (
          <div className="card p-6 text-center">
            <div className="loading-spinner mx-auto mb-2"></div>
            <p className="body-text">Loading workflow data...</p>
          </div>
        ) : (
          <>
            {/* Scheduled Runs */}
            <section className="section">
              <h2 className="heading-2 mb-4">Scheduled Runs</h2>
              <div className="card">
                {scheduledWorkflows.length === 0 ? (
                  <div className="card-body text-center">
                    <p className="body-text">No scheduled workflows found</p>
                    <p className="small-text mt-2">Use the "Schedule" option when running a workflow to plan future runs</p>
                  </div>
                ) : (
                  <div className="table-container">
                    <table className="table">
                      <thead>
                        <tr>
                          <th>Scheduled Time</th>
                          <th>Workflow</th>
                          <th>Parameters</th>
                          <th>Status</th>
                        </tr>
                      </thead>
                      <tbody>
                        {scheduledWorkflows.map((workflow, index) => (
                          <tr key={index}>
                            <td>{workflow.next_run ? format(new Date(workflow.next_run), 'MMM d, yyyy h:mm a') : 'N/A'}</td>
                            <td>{workflow.workflow_type === 'niche-scout' ? 'Niche-Scout' : 'Seed-to-Blueprint'}</td>
                            <td>
                              {workflow.parameters && Object.entries(workflow.parameters)
                                .filter(([_, value]) => value)
                                .map(([key, value]) => `${value}`)
                                .join(', ')}
                            </td>
                            <td><StatusBadge status="scheduled" /></td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </section>

            {/* Workflow History */}
            <section className="section">
              <h2 className="heading-2 mb-4">Workflow History</h2>
              <div className="card">
                {workflowHistory.length === 0 ? (
                  <div className="card-body text-center">
                    <p className="body-text">No workflow history found</p>
                    <p className="small-text mt-2">Run a workflow to see your execution history here</p>
                  </div>
                ) : (
                  <div className="table-container">
                    <table className="table">
                      <thead>
                        <tr>
                          <th>Run Date</th>
                          <th>Workflow</th>
                          <th>Parameters</th>
                          <th>Status</th>
                          <th>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {workflowHistory.map((workflow, index) => (
                          <tr key={index}>
                            <td>{workflow.started_at ? format(new Date(workflow.started_at), 'MMM d, yyyy h:mm a') : 'N/A'}</td>
                            <td>{workflow.workflow_type === 'niche-scout' ? 'Niche-Scout' : 'Seed-to-Blueprint'}</td>
                            <td>
                              {workflow.parameters && Object.entries(workflow.parameters)
                                .filter(([_, value]) => value)
                                .map(([key, value]) => `${value}`)
                                .join(', ')}
                            </td>
                            <td>
                              <StatusBadge 
                                status={
                                  workflow.status === 'completed' ? 'completed' :
                                  workflow.status === 'running' ? 'running' : 
                                  workflow.status === 'error' ? 'error' : 'pending'
                                } 
                              />
                            </td>
                            <td>
                              {workflow.status === 'completed' && (
                                <button
                                  onClick={() => router.push(`/workflows/${workflow.workflow_type}/results/${workflow.id}`)}
                                  className="button-sm button-primary"
                                >
                                  View Results
                                </button>
                              )}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            </section>
          </>
        )}
      </div>
    </MainLayout>
  );
}