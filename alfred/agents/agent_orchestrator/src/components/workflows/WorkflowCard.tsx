import { useState, useEffect } from "react";
import { Workflow } from "@/lib/data";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Play, Save, Settings, Clock, ChevronRight, AlertCircle, Wifi, WifiOff } from "lucide-react";
import { cn } from "@/lib/utils";
import { Input } from "@/components/ui/input";
import { useToast } from "@/hooks/use-toast";
import { NicheScoutWizard } from "@/components/wizards/NicheScoutWizard";
import { FinalPayload } from "@/types/niche-scout";
import { runNicheScout, getServiceStatus, checkServiceHealth } from "@/lib/youtube-service";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";

interface WorkflowCardProps {
  workflow: Workflow;
  onRunWorkflow: (workflowId: string) => void;
  asDialogTrigger?: boolean;
}

// Define the frequency type to match what's in the Workflow type
type FrequencyType = "hourly" | "daily" | "weekly" | "monthly" | "custom";

const WorkflowCard = ({ workflow, onRunWorkflow, asDialogTrigger = false }: WorkflowCardProps) => {
  const [isConfigOpen, setIsConfigOpen] = useState(false);
  const [frequency, setFrequency] = useState<FrequencyType>(workflow.frequency);
  const [timeOfDay, setTimeOfDay] = useState(workflow.timeOfDay || "");
  const [wizardOpen, setWizardOpen] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [serviceAvailable, setServiceAvailable] = useState(true);
  const [serviceError, setServiceError] = useState<string | undefined>(undefined);
  const { toast } = useToast();

  // Check service health on component mount and periodically
  useEffect(() => {
    const checkHealth = async () => {
      const status = getServiceStatus('socialIntel');
      setServiceAvailable(status.available);
      setServiceError(status.error);

      // Initial health check if needed
      if (!status.lastChecked || new Date().getTime() - status.lastChecked.getTime() > 60000) {
        const available = await checkServiceHealth('socialIntel');
        setServiceAvailable(available);
        if (!available) {
          const updatedStatus = getServiceStatus('socialIntel');
          setServiceError(updatedStatus.error);
        }
      }
    };

    // Check immediately on mount
    checkHealth();

    // Set up periodic checks every 60 seconds
    const intervalId = setInterval(checkHealth, 60000);

    // Clean up on unmount
    return () => clearInterval(intervalId);
  }, []);

  const formatDate = (date?: Date) => {
    if (!date) return "Not scheduled";
    return date.toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit"
    });
  };

  const handleRunWorkflow = () => {
    if (asDialogTrigger) {
      // If used as a dialog trigger, we don't execute the workflow directly
      return;
    }

    onRunWorkflow(workflow.id);
    toast({
      title: `${workflow.name} started`,
      description: "The workflow has been queued for execution.",
    });
  };

  const handleSave = () => {
    toast({
      title: "Workflow updated",
      description: `${workflow.name} schedule has been updated.`,
    });

    setIsConfigOpen(false);
  };

  // Create a handler that ensures type safety
  const handleFrequencyChange = (value: string) => {
    // TypeScript type guard to ensure value is a valid FrequencyType
    if (value === "hourly" || value === "daily" || value === "weekly" || value === "monthly" || value === "custom") {
      setFrequency(value);
    }
  };

  // Handle completion of Niche Scout wizard
  const handleNicheScoutComplete = async (payload: FinalPayload) => {
    try {
      // Show loading state
      setIsLoading(true);

      // If service is not available, force offline mode
      const forceOfflineMode = !serviceAvailable;

      if (forceOfflineMode) {
        // Show offline mode notification
        toast({
          title: "Service unavailable",
          description: "Running in offline mode with simulated data. Some features may be limited.",
          variant: "warning",
        });
      }

      // Call the API with the payload from the wizard
      const result = await runNicheScout({
        category: payload.category.value,
        subcategory: payload.subcategory.value,
        budget: payload.budget,
        dataSources: payload.dataSources,
        forceOfflineMode
      });

      // Handle success - store the result or update UI
      console.log("Niche scout completed:", result);

      // Store results in localStorage for the results dialog
      try {
        const storedResults = localStorage.getItem('youtube-results');
        let resultsArray = [];

        if (storedResults) {
          resultsArray = JSON.parse(storedResults);
        }

        // Add new result to the beginning
        resultsArray.unshift(result);

        // Keep only the last 5 results
        if (resultsArray.length > 5) {
          resultsArray = resultsArray.slice(0, 5);
        }

        localStorage.setItem('youtube-results', JSON.stringify(resultsArray));
      } catch (err) {
        console.error('Failed to store results:', err);
      }

      // Check if running in offline mode based on the result status
      const isOfflineMode = result.status?.includes('offline');

      // Show success notification
      toast({
        title: isOfflineMode ? "Niche Scout completed (offline mode)" : "Niche Scout analysis complete",
        description: `Found ${result.trending_niches.length} trending niches in ${payload.subcategory.label}. Click "View Niche Scout Results" to see details.`,
        variant: isOfflineMode ? "default" : "default",
      });

      // Update service status based on API response
      if (!isOfflineMode && !serviceAvailable) {
        setServiceAvailable(true);
        setServiceError(undefined);
      }

    } catch (error) {
      console.error("Niche scout failed:", error);

      // Update service status if needed
      const status = getServiceStatus('socialIntel');
      setServiceAvailable(status.available);
      setServiceError(status.error);

      // Handle error with more specific messages
      const errorMessage = error instanceof Error ? error.message : "Unknown error";

      toast({
        title: "Niche Scout failed",
        description: errorMessage.includes("Failed to run")
          ? errorMessage
          : "Could not complete analysis. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsLoading(false);
      setWizardOpen(false);
    }
  };

  return (
    <div
      className={cn(
        "border rounded-lg p-4 transition-all duration-200 hover:bg-accent/20",
        workflow.status === "error" && "border-error/40",
        workflow.status === "paused" && "border-muted"
      )}
    >
      {isConfigOpen ? (
        <div className="space-y-4">
          <div className="flex items-center justify-between mb-1">
            <h3 className="font-medium">{workflow.name}</h3>
            <ChevronRight className="h-4 w-4 text-muted-foreground" />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <label className="text-xs font-medium">Frequency</label>
              <Select value={frequency} onValueChange={handleFrequencyChange}>
                <SelectTrigger>
                  <SelectValue placeholder="Select frequency" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="hourly">Hourly</SelectItem>
                  <SelectItem value="daily">Daily</SelectItem>
                  <SelectItem value="weekly">Weekly</SelectItem>
                  <SelectItem value="monthly">Monthly</SelectItem>
                  <SelectItem value="custom">Custom</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <label className="text-xs font-medium">Time</label>
              <Input
                type="time"
                value={timeOfDay}
                onChange={(e) => setTimeOfDay(e.target.value)}
              />
            </div>
          </div>

          <Button
            variant="outline"
            size="sm"
            onClick={handleSave}
            className="w-full sm:w-auto"
          >
            <Save className="mr-1 h-3.5 w-3.5" />
            Save
          </Button>
        </div>
      ) : (
        <div className="flex items-center justify-between">
          <div className="flex-1">
            <div className="flex items-center justify-between mb-1">
              <div className="flex items-center gap-2">
                <h3 className="font-medium">{workflow.name}</h3>
                <TooltipProvider>
                  <Tooltip>
                    <TooltipTrigger asChild>
                      <div className="inline-flex">
                        {serviceAvailable ? (
                          <Wifi className="h-3.5 w-3.5 text-green-500" />
                        ) : (
                          <WifiOff className="h-3.5 w-3.5 text-amber-500" />
                        )}
                      </div>
                    </TooltipTrigger>
                    <TooltipContent>
                      <p>
                        {serviceAvailable
                          ? "Service available: Connected to Social Intelligence API"
                          : `Service unavailable: ${serviceError || "Connection error"}. Running in offline mode.`}
                      </p>
                    </TooltipContent>
                  </Tooltip>
                </TooltipProvider>
              </div>
              <ChevronRight className="h-4 w-4 text-muted-foreground" />
            </div>
            <p className="text-sm text-muted-foreground mb-2">{workflow.description}</p>

            <div className="flex items-center text-xs text-muted-foreground">
              <Clock className="h-3.5 w-3.5 mr-1.5" />
              <span>Last run: {formatDate(workflow.lastRun)}</span>
              <span className="mx-2">•</span>
              <span>Next run: {formatDate(workflow.nextRun)}</span>
              {!serviceAvailable && (
                <>
                  <span className="mx-2">•</span>
                  <span className="text-amber-500 flex items-center">
                    <AlertCircle className="h-3.5 w-3.5 mr-1" />
                    Offline Mode
                  </span>
                </>
              )}
            </div>
          </div>

          <div className="flex gap-2 ml-4">
            {workflow.name === "Niche-Scout" ? (
              <>
                <Button
                  variant="default"
                  size="sm"
                  onClick={() => setWizardOpen(true)}
                  className={cn(
                    "whitespace-nowrap",
                    !serviceAvailable && "border-amber-300 text-amber-700 bg-amber-50 hover:bg-amber-100"
                  )}
                  disabled={isLoading}
                >
                  {isLoading ? "Running..." : (
                    <span className="flex items-center gap-1">
                      {!serviceAvailable && <WifiOff className="h-3.5 w-3.5" />}
                      {serviceAvailable ? "Configure Analysis" : "Run in Offline Mode"}
                    </span>
                  )}
                </Button>

                <NicheScoutWizard
                  trigger={<div />}
                  onComplete={handleNicheScoutComplete}
                  open={wizardOpen}
                  onOpenChange={setWizardOpen}
                />
              </>
            ) : (
              <>
                <Button
                  variant="default"
                  size="sm"
                  onClick={handleRunWorkflow}
                  className={cn(
                    "whitespace-nowrap",
                    !serviceAvailable && "border-amber-300 text-amber-700 bg-amber-50 hover:bg-amber-100"
                  )}
                >
                  <span className="flex items-center gap-1">
                    {serviceAvailable ? <Play className="h-3.5 w-3.5" /> : <WifiOff className="h-3.5 w-3.5" />}
                    {serviceAvailable ? "Run Now" : "Run in Offline Mode"}
                  </span>
                </Button>

                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setIsConfigOpen(true)}
                  className="whitespace-nowrap"
                >
                  <Settings className="mr-1 h-3.5 w-3.5" />
                  Configure
                </Button>
              </>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default WorkflowCard;
