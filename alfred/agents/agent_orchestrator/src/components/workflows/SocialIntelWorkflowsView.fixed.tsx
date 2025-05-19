import { useState, useEffect } from "react";
import { socialIntelWorkflows } from "@/lib/data";
import WorkflowCard from "./WorkflowCard";
import { useToast } from "@/hooks/use-toast";
import { LayoutList, AlertCircle, Wifi, WifiOff } from "lucide-react";
import { Button } from "@/components/ui/button";
import { IdeaGeneratorWizard } from "@/components/wizards/IdeaGeneratorWizard";
import { NicheScoutWizard } from "@/components/wizards/NicheScoutWizard";
import { FinalPayload } from "@/types/niche-scout";
import YouTubeResultsDialog from "@/components/ui/youtube-results-dialog";
import { runNicheScout, runSeedToBlueprint } from "@/lib/youtube-service";
import { getServiceStatus, checkServiceHealth } from "@/lib/youtube-service";
import { cn } from "@/lib/utils";
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";

interface SocialIntelWorkflowsViewProps {
  agentId: string;
}

const SocialIntelWorkflowsView = ({ agentId }: SocialIntelWorkflowsViewProps) => {
  const [workflows] = useState(socialIntelWorkflows);
  const [serviceAvailable, setServiceAvailable] = useState(true);
  const [serviceError, setServiceError] = useState<string | undefined>(undefined);
  const [isLoading, setIsLoading] = useState(false);
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

  const handleRunWorkflow = async (workflowId: string) => {
    const workflow = workflows.find(w => w.id === workflowId);
    if (workflow) {
      console.log(`Running workflow: ${workflow.name}`);

      setIsLoading(true);

      try {
        // Determine if we need to force offline mode
        const forceOfflineMode = !serviceAvailable;

        if (forceOfflineMode) {
          toast({
            title: "Service unavailable",
            description: "Running in offline mode with simulated data. Some features may be limited.",
            variant: "warning",
          });
        }

        if (workflow.name === "Seed-to-Blueprint") {
          // For Seed-to-Blueprint, use real service call
          const result = await runSeedToBlueprint({
            video_url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", // Default example video
            forceOfflineMode
          });

          // Check if running in offline mode based on the result status
          const isOfflineMode = result.status?.includes('offline');

          // Store results in localStorage for the results dialog
          try {
            const storedResults = localStorage.getItem('youtube-blueprint-results');
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

            localStorage.setItem('youtube-blueprint-results', JSON.stringify(resultsArray));
          } catch (err) {
            console.error('Failed to store blueprint results:', err);
          }

          toast({
            title: isOfflineMode ? "Blueprint created (offline mode)" : "Blueprint created",
            description: "Channel blueprint has been generated. Click View Results to see details.",
            variant: "default",
          });

          // Update service status if needed
          if (!isOfflineMode && !serviceAvailable) {
            setServiceAvailable(true);
            setServiceError(undefined);
          }
        } else {
          // For other workflows
          toast({
            title: forceOfflineMode ? `${workflow.name} completed (offline mode)` : `${workflow.name} completed`,
            description: "The workflow has been completed successfully.",
            variant: "default",
          });
        }
      } catch (error) {
        console.error(`Error running workflow ${workflow.name}:`, error);

        // Update service status
        const status = getServiceStatus('socialIntel');
        setServiceAvailable(status.available);
        setServiceError(status.error);

        // Handle error with specific messages
        const errorMessage = error instanceof Error ? error.message : "Unknown error";

        toast({
          title: `${workflow.name} failed`,
          description: errorMessage.includes("Failed to run")
            ? errorMessage
            : "Could not complete workflow. Please try again.",
          variant: "destructive",
        });
      } finally {
        setIsLoading(false);
      }
    }
  };

  const handleAdoptIdea = (idea: { title: string; description: string }) => {
    console.log("Adopted", idea.title);
    toast({
      title: "Idea Saved",
      description: `"${idea.title}" has been added to your workflow ideas.`,
      variant: "default",
    });
  };

  // This is only for the NicheScoutWizard triggered from the view, not the WorkflowCard
  const handleNicheScoutComplete = async (payload: FinalPayload) => {
    try {
      setIsLoading(true);

      // Notify that analysis has started
      console.log("Niche-Scout analysis started with payload:", payload);
      toast({
        title: "Niche Scout started",
        description: `Analysis for ${payload.category.label} > ${payload.subcategory.label} has been initiated.`,
        variant: "default",
      });

      // Determine if we need to force offline mode
      const forceOfflineMode = !serviceAvailable;

      if (forceOfflineMode) {
        toast({
          title: "Service unavailable",
          description: "Running in offline mode with simulated data. Some features may be limited.",
          variant: "warning",
        });
      }

      // Call the actual API
      const result = await runNicheScout({
        category: payload.category.value,
        subcategory: payload.subcategory.value,
        budget: payload.budget,
        dataSources: payload.dataSources,
        forceOfflineMode
      });

      // Store results in localStorage
      try {
        const storedResults = localStorage.getItem('youtube-results');
        let resultsArray = [];

        if (storedResults) {
          resultsArray = JSON.parse(storedResults);
        }

        resultsArray.unshift(result);

        if (resultsArray.length > 5) {
          resultsArray = resultsArray.slice(0, 5);
        }

        localStorage.setItem('youtube-results', JSON.stringify(resultsArray));
      } catch (err) {
        console.error('Failed to store results:', err);
      }

      // Check if running in offline mode
      const isOfflineMode = result.status?.includes('offline');

      // Show completion notification
      toast({
        title: isOfflineMode ? "Niche Scout completed (offline mode)" : "Niche Scout completed",
        description: `Found ${result.trending_niches.length} trending niches in ${payload.subcategory.label}. Click "View Niche Scout Results" to see details.`,
        variant: "default",
      });

      // Update service status if needed
      if (!isOfflineMode && !serviceAvailable) {
        setServiceAvailable(true);
        setServiceError(undefined);
      }
    } catch (error) {
      console.error("Niche scout failed:", error);

      // Update service status
      const status = getServiceStatus('socialIntel');
      setServiceAvailable(status.available);
      setServiceError(status.error);

      // Handle error with specific messages
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
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2 text-muted-foreground">
          <LayoutList className="h-4 w-4" />
          <span className="text-sm font-medium">Workflows ({workflows.length})</span>

          <TooltipProvider>
            <Tooltip>
              <TooltipTrigger asChild>
                <div className="inline-flex ml-2">
                  {serviceAvailable ? (
                    <Wifi className="h-4 w-4 text-green-500" />
                  ) : (
                    <WifiOff className="h-4 w-4 text-amber-500" />
                  )}
                </div>
              </TooltipTrigger>
              <TooltipContent>
                <p>
                  {serviceAvailable
                    ? "Social Intelligence API: Connected"
                    : `Social Intelligence API: Unavailable (${serviceError || "Connection error"})`}
                </p>
              </TooltipContent>
            </Tooltip>
          </TooltipProvider>

          {!serviceAvailable && (
            <span className="text-xs text-amber-500 flex items-center">
              <AlertCircle className="h-3.5 w-3.5 mr-1" />
              Offline Mode
            </span>
          )}
        </div>
        <div className="hidden sm:flex items-center gap-2">
          <YouTubeResultsDialog />
          <IdeaGeneratorWizard
            trigger={<Button variant="outline" size="sm">Need Title Ideas?</Button>}
            onAdopt={handleAdoptIdea}
          />
        </div>
      </div>

      {!serviceAvailable && (
        <div className="bg-amber-50 border border-amber-200 rounded-md p-2 mb-4 text-amber-700 text-sm">
          <div className="flex items-center gap-2">
            <AlertCircle className="h-4 w-4" />
            <span>Social Intelligence service is currently unavailable. Workflows will run in offline mode with simulated data.</span>
          </div>
        </div>
      )}

      <div className="space-y-3">
        {workflows.map((workflow) => (
          workflow.name === "Niche-Scout" ? (
            <NicheScoutWizard
              key={workflow.id}
              trigger={
                <WorkflowCard
                  workflow={workflow}
                  onRunWorkflow={() => {}} // We're using the card as a trigger, so this is empty
                />
              }
              onComplete={handleNicheScoutComplete}
            />
          ) : (
            <WorkflowCard
              key={workflow.id}
              workflow={workflow}
              onRunWorkflow={handleRunWorkflow}
            />
          )
        ))}
      </div>
    </div>
  );
};

export default SocialIntelWorkflowsView;
