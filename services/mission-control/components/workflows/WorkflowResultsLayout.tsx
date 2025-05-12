import React, { ReactNode } from 'react';
import Link from 'next/link';
import StatusBadge from '../ui/StatusBadge';

interface Tab {
  id: string;
  label: string;
}

interface WorkflowResultsLayoutProps {
  title: string;
  status: 'running' | 'completed' | 'error' | 'pending' | 'scheduled';
  runDate: string;
  backUrl: string;
  tabs: Tab[];
  activeTab: string;
  onTabChange: (tabId: string) => void;
  children: ReactNode;
}

export default function WorkflowResultsLayout({
  title,
  status,
  runDate,
  backUrl,
  tabs,
  activeTab,
  onTabChange,
  children
}: WorkflowResultsLayoutProps) {
  return (
    <div className="space-y-6">
      <div className="mb-6">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between">
          <h1 className="heading-1">{title}</h1>
          
          <div className="mt-4 md:mt-0">
            <Link href={backUrl} className="button-secondary">
              Back
            </Link>
          </div>
        </div>
      </div>
      
      {/* Metadata */}
      <div className="card card-body mb-6">
        <div className="flex flex-col md:flex-row md:justify-between gap-4">
          <div>
            <span className="small-text">Run Date</span>
            <p className="body-text">{new Date(runDate).toLocaleString()}</p>
          </div>
          
          <div>
            <span className="small-text">Status</span>
            <div className="mt-1">
              <StatusBadge status={status} />
            </div>
          </div>
        </div>
      </div>
      
      {/* Tabs */}
      <div className="border-b border-gray-200 dark:border-gray-700">
        <div className="flex space-x-4 overflow-x-auto">
          {tabs.map(tab => (
            <button
              key={tab.id}
              className={`
                py-2 px-1 border-b-2 text-sm font-medium
                ${
                  activeTab === tab.id
                    ? 'border-blue-600 text-blue-600 dark:text-blue-400'
                    : 'border-transparent text-gray-500 dark:text-gray-400'
                }
              `}
              onClick={() => onTabChange(tab.id)}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>
      
      {/* Content */}
      <div className="mt-6">
        {children}
      </div>
    </div>
  );
}