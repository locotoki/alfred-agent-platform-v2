
import { cn } from "@/lib/utils";

type StatusType = "active" | "idle" | "error" | "offline";

interface StatusPillProps {
  status: StatusType;
  children?: React.ReactNode;
  className?: string;
}

const statusClasses: Record<StatusType, string> = {
  active: "bg-green-50 text-green-700 border border-green-200",
  idle: "bg-yellow-50 text-yellow-700 border border-yellow-200",
  error: "bg-red-50 text-red-700 border border-red-200",
  offline: "bg-gray-50 text-gray-700 border border-gray-200",
};

const StatusPill = ({ status, children, className }: StatusPillProps) => {
  return (
    <span
      className={cn(
        "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
        statusClasses[status],
        className
      )}
    >
      <span className="w-1.5 h-1.5 rounded-full mr-1.5 bg-current animate-pulse" />
      {children || status.charAt(0).toUpperCase() + status.slice(1)}
    </span>
  );
};

export default StatusPill;
