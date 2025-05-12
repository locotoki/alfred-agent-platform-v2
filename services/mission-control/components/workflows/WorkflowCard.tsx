import React from 'react';
import Link from 'next/link';

interface WorkflowCardProps {
  title: string;
  description: string;
  href: string;
  isNew?: boolean;
}

export default function WorkflowCard({
  title,
  description,
  href,
  isNew = false
}: WorkflowCardProps) {
  return (
    <Link href={href} className="block">
      <div className="card">
        <div className="card-body">
          <div className="flex justify-between mb-2">
            <h3 className="heading-3">{title}</h3>
            
            {isNew && (
              <span className="badge-blue">New</span>
            )}
          </div>
          
          <p className="body-text mb-4">{description}</p>
          
          <div className="flex justify-end">
            <span className="button-primary">Run Workflow</span>
          </div>
        </div>
      </div>
    </Link>
  );
}