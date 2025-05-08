
import { useState } from "react";
import { Workflow } from "@/lib/data";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Play, Save, Settings, Clock, ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";
import { Input } from "@/components/ui/input";
import { useToast } from "@/hooks/use-toast";
import { NicheScoutWizard } from "@/components/wizards/NicheScoutWizard";
import { FinalPayload } from "@/types/niche-scout";
import { runNicheScout } from "@/lib/youtube-service";

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
  const { toast } = useToast();
  
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
      
      // Call the API with the payload from the wizard
      const result = await runNicheScout({
        category: payload.category.value,
        subcategory: payload.subcategory.value,
        budget: payload.budget,
        dataSources: payload.dataSources
      });
      
      // Handle success - store the result or update UI
      console.log("Niche scout completed:", result);
      
      // Show success notification
      toast({
        title: "Niche Scout analysis complete",
        description: `Found ${result.trending_niches.length} trending niches in ${payload.subcategory.label}`,
      });
      
    } catch (error) {
      // Handle error
      console.error("Niche scout failed:", error);
      toast({
        title: "Niche Scout failed",
        description: "Could not complete analysis. Please try again.",
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
              <h3 className="font-medium">{workflow.name}</h3>
              <ChevronRight className="h-4 w-4 text-muted-foreground" />
            </div>
            <p className="text-sm text-muted-foreground mb-2">{workflow.description}</p>
            
            <div className="flex items-center text-xs text-muted-foreground">
              <Clock className="h-3.5 w-3.5 mr-1.5" />
              <span>Last run: {formatDate(workflow.lastRun)}</span>
              <span className="mx-2">•</span>
              <span>Next run: {formatDate(workflow.nextRun)}</span>
            </div>
          </div>
          
          <div className="flex gap-2 ml-4">
            {workflow.name === "Niche-Scout" ? (
              <>
                <Button 
                  variant="default" 
                  size="sm" 
                  onClick={() => setWizardOpen(true)}
                  className="whitespace-nowrap"
                  disabled={isLoading}
                >
                  {isLoading ? "Running..." : "Configure Analysis"}
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
                  className="whitespace-nowrap"
                >
                  <Play className="mr-1 h-3.5 w-3.5" />
                  Run Now
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
