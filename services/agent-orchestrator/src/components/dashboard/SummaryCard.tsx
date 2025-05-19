
import { ReactNode } from "react";
import { ArrowUp, ArrowDown } from "lucide-react";
import { cn } from "@/lib/utils";

interface SummaryCardProps {
  title: string;
  value: string | number;
  icon: ReactNode;
  change?: number;
  changeLabel?: string;
  className?: string;
}

const SummaryCard = ({
  title,
  value,
  icon,
  change,
  changeLabel,
  className,
}: SummaryCardProps) => {
  const isPositive = change && change > 0;
  const isNegative = change && change < 0;

  return (
    <div className={cn("card-shadow p-5", className)}>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-muted-foreground mb-1">{title}</p>
          <h3 className="text-2xl font-bold">{value}</h3>

          {typeof change !== "undefined" && (
            <div className="flex items-center mt-2">
              <span
                className={cn(
                  "flex items-center text-xs font-medium",
                  isPositive && "text-success",
                  isNegative && "text-error",
                  !isPositive && !isNegative && "text-muted-foreground"
                )}
              >
                {isPositive && <ArrowUp className="mr-1 h-3 w-3" />}
                {isNegative && <ArrowDown className="mr-1 h-3 w-3" />}
                {Math.abs(change)}%
              </span>
              {changeLabel && (
                <span className="ml-1.5 text-xs text-muted-foreground">
                  {changeLabel}
                </span>
              )}
            </div>
          )}
        </div>

        <div className="bg-primary/10 p-2 rounded-lg">
          {icon}
        </div>
      </div>
    </div>
  );
};

export default SummaryCard;
