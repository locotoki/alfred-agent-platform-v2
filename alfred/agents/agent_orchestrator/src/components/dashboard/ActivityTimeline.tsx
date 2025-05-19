import { useState, useEffect } from "react";
import { cn } from "@/lib/utils";
import { Users, AlertCircle, Check, Clock, Zap, FileText } from "lucide-react";
import { GradientButton } from "../ui/buttons/GradientButton";

interface Activity {
  id: string;
  type: "task" | "error" | "agent" | "system";
  message: string;
  timestamp: Date;
  status?: "completed" | "failed" | "pending";
}

const generateActivity = (): Activity => {
  const types = ["task", "error", "agent", "system"];
  const type = types[Math.floor(Math.random() * types.length)] as Activity["type"];

  const messages = {
    task: [
      "Niche-Scout workflow ran successfully",
      "Seed-to-Blueprint workflow completed",
      "Agent tasks updated automatically",
      "Daily summary report generated",
      "Analytics data aggregation completed"
    ],
    error: [
      "API rate limit exceeded",
      "Connection to database failed",
      "Authentication token expired",
      "Data validation error detected",
      "Task timeout after 30 seconds"
    ],
    agent: [
      "Social Intelligence agent deployed new version",
      "Financial Tax agent status changed to active",
      "Legal Compliance agent completed maintenance",
      "Alfred Bot connected to new channel",
      "Taxonomy integration agent synchronized"
    ],
    system: [
      "System backup completed successfully",
      "Database migration applied",
      "Storage optimization reduced usage by 15%",
      "Scheduled maintenance completed",
      "New configuration deployed"
    ]
  };

  const message = messages[type][Math.floor(Math.random() * messages[type].length)];

  const statuses = ["completed", "failed", "pending"];
  const status = type === "error"
    ? "failed"
    : statuses[Math.floor(Math.random() * (type === "task" ? 3 : 2))]; // errors are always failed

  return {
    id: Math.random().toString(36).substring(2, 9),
    type,
    message,
    timestamp: new Date(Date.now() - Math.floor(Math.random() * 8640000)), // Random time within 24 hours
    status: type === "task" || type === "error" ? status as "completed" | "failed" | "pending" : undefined
  };
};

const ActivityTimeline = () => {
  const [activities, setActivities] = useState<Activity[]>([]);
  const [animateIndex, setAnimateIndex] = useState<number | null>(null);

  useEffect(() => {
    // Initial activities
    setActivities(Array(8).fill(null).map(() => generateActivity()).sort((a, b) =>
      b.timestamp.getTime() - a.timestamp.getTime()
    ));

    // Add new activity every 8-12 seconds
    const interval = setInterval(() => {
      const newActivity = generateActivity();
      newActivity.timestamp = new Date();

      setActivities(prev => {
        const updated = [newActivity, ...prev.slice(0, 9)]; // Keep last 10 items
        return updated.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
      });

      setAnimateIndex(0);
      setTimeout(() => setAnimateIndex(null), 1000);
    }, Math.random() * 4000 + 8000);

    return () => clearInterval(interval);
  }, []);

  const formatTime = (date: Date) => {
    const now = new Date();
    const diff = (now.getTime() - date.getTime()) / 1000;

    if (diff < 60) return "Just now";
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    return `${Math.floor(diff / 86400)}d ago`;
  };

  const getActivityIcon = (type: Activity["type"]) => {
    switch (type) {
      case "task":
        return <FileText className="h-5 w-5" />;
      case "error":
        return <AlertCircle className="h-5 w-5" />;
      case "agent":
        return <Users className="h-5 w-5" />;
      case "system":
        return <Zap className="h-5 w-5" />;
      default:
        return <Clock className="h-5 w-5" />;
    }
  };

  const getStatusIcon = (status?: Activity["status"]) => {
    if (!status) return null;

    switch (status) {
      case "completed":
        return <Check className="h-4 w-4 text-green-500" />;
      case "failed":
        return <AlertCircle className="h-4 w-4 text-red-500" />;
      case "pending":
        return <Clock className="h-4 w-4 text-amber-500" />;
      default:
        return null;
    }
  };

  return (
    <div className="card-shadow p-6">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold">Recent Activity</h2>
        <GradientButton
          variant="primary"
          size="sm"
          iconBefore={<Clock className="h-4 w-4" />}
        >
          View All
        </GradientButton>
      </div>

      <div className="space-y-4">
        {activities.map((activity, index) => (
          <div
            key={activity.id}
            className={cn(
              "flex items-start space-x-3 p-3 rounded-lg transition-all border-l-4",
              index === animateIndex && "slide-in-right",
              activity.type === "error" && "border-l-red-500 bg-red-50 dark:bg-red-900/10",
              activity.type === "task" && "border-l-blue-500 bg-blue-50 dark:bg-blue-900/10",
              activity.type === "agent" && "border-l-purple-500 bg-purple-50 dark:bg-purple-900/10",
              activity.type === "system" && "border-l-green-500 bg-green-50 dark:bg-green-900/10",
            )}
          >
            <div className={cn(
              "rounded-full p-2 flex-shrink-0",
              activity.type === "error" && "bg-red-100 text-red-600 dark:bg-red-900/20 dark:text-red-400",
              activity.type === "task" && "bg-blue-100 text-blue-600 dark:bg-blue-900/20 dark:text-blue-400",
              activity.type === "agent" && "bg-purple-100 text-purple-600 dark:bg-purple-900/20 dark:text-purple-400",
              activity.type === "system" && "bg-green-100 text-green-600 dark:bg-green-900/20 dark:text-green-400",
            )}>
              {getActivityIcon(activity.type)}
            </div>

            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between">
                <p className={cn(
                  "font-medium",
                  activity.type === "error" && "text-red-800 dark:text-red-300",
                  activity.type === "task" && "text-blue-800 dark:text-blue-300",
                  activity.type === "agent" && "text-purple-800 dark:text-purple-300",
                  activity.type === "system" && "text-green-800 dark:text-green-300",
                )}>
                  {activity.message}
                </p>
                <span className="text-xs text-gray-500 dark:text-gray-400 ml-2 flex-shrink-0 flex items-center">
                  {activity.status && (
                    <span className="mr-2 flex items-center">
                      {getStatusIcon(activity.status)}
                    </span>
                  )}
                  {formatTime(activity.timestamp)}
                </span>
              </div>
              <p className="text-sm text-gray-600 dark:text-gray-300">
                {activity.type.charAt(0).toUpperCase() + activity.type.slice(1)}
                {activity.status && ` • ${activity.status.charAt(0).toUpperCase() + activity.status.slice(1)}`}
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ActivityTimeline;
