import React, { useState } from 'react';
import { ChevronDown, ChevronRight, AlertCircle, AlertTriangle, Info } from 'lucide-react';
import { cn } from '@/lib/utils';
import { Badge } from '@/components/ui/badge';
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '@/components/ui/accordion';

interface AlertGroup {
  id: string;
  key: string;
  count: number;
  first_seen: string;
  last_seen: string;
  severity: 'critical' | 'warning' | 'info';
}

interface GroupedAlertsProps {
  groups: AlertGroup[];
  featureFlags?: {
    ALERT_GROUPING_ENABLED?: boolean;
  };
}

const severityConfig = {
  critical: {
    color: 'destructive',
    icon: AlertCircle,
    bgColor: 'bg-red-50',
  },
  warning: {
    color: 'warning',
    icon: AlertTriangle,
    bgColor: 'bg-yellow-50',
  },
  info: {
    color: 'secondary',
    icon: Info,
    bgColor: 'bg-blue-50',
  },
};

export function GroupedAlerts({ groups, featureFlags = {} }: GroupedAlertsProps) {
  // Feature flag check
  if (!featureFlags.ALERT_GROUPING_ENABLED) {
    return null;
  }

  const [openItems, setOpenItems] = useState<string[]>([]);

  const formatTime = (timestamp: string) => {
    const date = new Date(timestamp);
    return date.toLocaleString();
  };

  const formatDuration = (first: string, last: string) => {
    const firstDate = new Date(first);
    const lastDate = new Date(last);
    const diff = lastDate.getTime() - firstDate.getTime();
    const minutes = Math.floor(diff / 60000);
    return `${minutes}m`;
  };

  return (
    <div className="w-full space-y-4">
      <h2 className="text-2xl font-bold">Grouped Alerts</h2>
      
      <Accordion
        type="multiple"
        value={openItems}
        onValueChange={setOpenItems}
        className="w-full"
      >
        {groups.map((group) => {
          const config = severityConfig[group.severity];
          const Icon = config.icon;
          
          return (
            <AccordionItem key={group.id} value={group.id}>
              <AccordionTrigger className="hover:no-underline">
                <div className="flex items-center justify-between w-full pr-4">
                  <div className="flex items-center gap-3">
                    <Icon className={cn("h-5 w-5", {
                      "text-red-600": group.severity === 'critical',
                      "text-yellow-600": group.severity === 'warning',
                      "text-blue-600": group.severity === 'info',
                    })} />
                    
                    <span className="font-medium text-left">
                      {group.key}
                    </span>
                    
                    <Badge variant={config.color as any}>
                      {group.count} alerts
                    </Badge>
                    
                    <Badge variant="outline">
                      {formatDuration(group.first_seen, group.last_seen)}
                    </Badge>
                  </div>
                  
                  <div className="text-sm text-muted-foreground">
                    {formatTime(group.last_seen)}
                  </div>
                </div>
              </AccordionTrigger>
              
              <AccordionContent>
                <div className={cn("p-4 rounded-lg", config.bgColor)}>
                  <div className="space-y-2">
                    <div>
                      <span className="font-medium">First seen:</span>{' '}
                      {formatTime(group.first_seen)}
                    </div>
                    <div>
                      <span className="font-medium">Last seen:</span>{' '}
                      {formatTime(group.last_seen)}
                    </div>
                    <div>
                      <span className="font-medium">Alert count:</span>{' '}
                      {group.count}
                    </div>
                    <div>
                      <span className="font-medium">Severity:</span>{' '}
                      <Badge variant={config.color as any}>
                        {group.severity}
                      </Badge>
                    </div>
                  </div>
                  
                  <div className="mt-4">
                    <button className="text-sm text-primary hover:underline">
                      View all alerts →
                    </button>
                  </div>
                </div>
              </AccordionContent>
            </AccordionItem>
          );
        })}
      </Accordion>
      
      {groups.length === 0 && (
        <div className="text-center py-8 text-muted-foreground">
          No grouped alerts to display
        </div>
      )}
    </div>
  );
}

export default GroupedAlerts;