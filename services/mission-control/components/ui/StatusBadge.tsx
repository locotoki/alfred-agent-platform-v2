import React from 'react';

type StatusType = 'running' | 'completed' | 'error' | 'pending' | 'scheduled';

interface StatusBadgeProps {
  status: StatusType;
  text?: string;
}

export default function StatusBadge({ status, text }: StatusBadgeProps) {
  const statusConfig = {
    running: {
      class: 'badge-blue',
      defaultText: 'Running'
    },
    completed: {
      class: 'badge-green',
      defaultText: 'Completed'
    },
    error: {
      class: 'badge-red',
      defaultText: 'Error'
    },
    pending: {
      class: 'badge-yellow',
      defaultText: 'Pending'
    },
    scheduled: {
      class: 'badge-gray',
      defaultText: 'Scheduled'
    }
  };

  const config = statusConfig[status];
  const displayText = text || config.defaultText;

  return (
    <span className={config.class}>
      {displayText}
    </span>
  );
}