
import React from "react";
import { Category, DataSourceConfig } from "@/types/niche-scout";
import { Slider } from "@/components/ui/slider";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { Collapsible, CollapsibleTrigger, CollapsibleContent } from "@/components/ui/collapsible";
import { COST_PER_SOURCE, COST_TOOLTIP, BUDGET_MIN, BUDGET_MAX } from "@/config/costRules";
import { formatCurrency, formatTime } from "@/lib/utils";

interface StepThreeProps {
  category: Category;
  subcategory: Category;
  budget: number;
  setBudget: (budget: number) => void;
  dataSources: DataSourceConfig;
  setDataSources: (sources: DataSourceConfig) => void;
  estimatedTime: number;
  estimatedCost: number;
  lastAccuracy?: { diffCost: number; diffEta: number } | null;
}

export const StepThree: React.FC<StepThreeProps> = ({
  category,
  subcategory,
  budget,
  setBudget,
  dataSources,
  setDataSources,
  estimatedTime,
  estimatedCost,
  lastAccuracy,
}) => {
  const handleDataSourceChange = (source: keyof DataSourceConfig) => {
    setDataSources({
      ...dataSources,
      [source]: !dataSources[source],
    });
  };

  // Check if any non-default sources are enabled
  const hasNonDefaultSources = Object.values(dataSources).some(value => !value);

  return (
    <div className="space-y-6">
      <div className="space-y-2">
        <h2 className="text-xl font-semibold">Review Your Research</h2>
        <p className="text-sm text-muted-foreground">
          Confirm your niche research settings and adjust if needed
        </p>
      </div>

      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-4 p-4 bg-muted/50 rounded-lg">
          <div>
            <div className="text-sm font-medium text-muted-foreground">Category</div>
            <div className="font-medium">{category.label}</div>
          </div>
          <div>
            <div className="text-sm font-medium text-muted-foreground">Subcategory</div>
            <div className="font-medium">{subcategory.label}</div>
          </div>
        </div>

        <div className="space-y-3">
          <h3 className="text-sm font-medium">Budget</h3>
          <div className="space-y-2">
            <div className="flex justify-between text-xs mb-1">
              <span>${BUDGET_MIN}</span>
              <span>${BUDGET_MAX}</span>
            </div>
            <Slider
              value={[budget]}
              min={BUDGET_MIN}
              max={BUDGET_MAX}
              step={10}
              onValueChange={(values) => setBudget(values[0])}
            />
            <div className="text-center text-lg font-semibold">
              {formatCurrency(budget)}
            </div>
          </div>
        </div>

        <Collapsible defaultOpen={hasNonDefaultSources}>
          <CollapsibleTrigger className="w-full text-left font-medium">
            Advanced ▸ Data Sources
          </CollapsibleTrigger>
          <CollapsibleContent className="mt-4 space-y-2">
            <div className="grid grid-cols-2 gap-3">
              {Object.entries(COST_PER_SOURCE).map(([key, cost]) => {
                const sourceKey = key as keyof DataSourceConfig;
                return (
                  <div key={key} className="flex items-center space-x-2">
                    <Checkbox
                      id={`source-${key}`}
                      checked={dataSources[sourceKey]}
                      onCheckedChange={() => handleDataSourceChange(sourceKey)}
                    />
                    <label
                      htmlFor={`source-${key}`}
                      className="flex justify-between items-center w-full text-sm cursor-pointer"
                    >
                      <span className="capitalize">{key}</span>
                      <Tooltip>
                        <TooltipTrigger asChild>
                          <span className="text-xs text-muted-foreground">
                            ${cost.toFixed(2)}/k
                          </span>
                        </TooltipTrigger>
                        <TooltipContent side="top">
                          {COST_TOOLTIP[sourceKey]}
                        </TooltipContent>
                      </Tooltip>
                    </label>
                  </div>
                );
              })}
            </div>
          </CollapsibleContent>
        </Collapsible>

        <div className="grid grid-cols-2 gap-4 p-4 bg-muted/50 rounded-lg relative">
          {lastAccuracy && (
            <Badge
              variant={Math.max(lastAccuracy.diffCost, lastAccuracy.diffEta) < 0.1 ? "secondary" : "destructive"}
              className="absolute top-2 right-2"
            >
              ±{Math.round(Math.max(lastAccuracy.diffCost, lastAccuracy.diffEta) * 100)}% vs. last run
            </Badge>
          )}
          <div>
            <div className="text-sm font-medium text-muted-foreground">Est. Time</div>
            <div className="font-medium">{formatTime(estimatedTime)}</div>
          </div>
          <div>
            <div className="text-sm font-medium text-muted-foreground">Est. Cost</div>
            <div className="font-medium">{formatCurrency(estimatedCost)}</div>
          </div>
        </div>
      </div>
    </div>
  );
};
