
import { useEffect, useState } from "react";
import { useParams, Link, useNavigate } from "react-router-dom";
import { ArrowLeft, Play, Settings, Code, Activity } from "lucide-react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import StatusPill from "../ui/StatusPill";
import { agents } from "@/lib/data";
import { Button } from "@/components/ui/button";
import SocialIntelWorkflowsView from "../workflows/SocialIntelWorkflowsView";

const AgentDetailView = () => {
  const { agentId } = useParams<{ agentId: string }>();
  const navigate = useNavigate();
  const [agent, setAgent] = useState<(typeof agents)[0] | undefined>(undefined);

  useEffect(() => {
    const foundAgent = agents.find(a => a.id === agentId);
    if (foundAgent) {
      setAgent(foundAgent);
    } else {
      navigate("/agents");
    }
  }, [agentId, navigate]);

  if (!agent) {
    return (
      <div className="flex items-center justify-center h-64">
        <p>Loading agent details...</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <Link
          to="/agents"
          className="inline-flex items-center text-sm text-muted-foreground hover:text-foreground mb-4"
        >
          <ArrowLeft className="mr-1 h-4 w-4" />
          Back to agents
        </Link>

        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <div className="flex items-center gap-3">
              <h1 className="text-2xl font-bold">{agent.name}</h1>
              <StatusPill status={agent.status} />
            </div>
            <p className="text-muted-foreground mt-1">{agent.description}</p>
          </div>

          <div className="flex items-center gap-3">
            <Button variant="outline" size="sm">
              <Settings className="mr-2 h-4 w-4" />
              Configure
            </Button>

            <Button
              size="sm"
              disabled={agent.status === "offline" || agent.status === "error"}
            >
              <Play className="mr-2 h-4 w-4" />
              Run
            </Button>
          </div>
        </div>
      </div>

      <Tabs defaultValue="workflows" className="w-full">
        <TabsList className="w-full sm:w-auto">
          <TabsTrigger value="workflows" className="flex items-center gap-1.5">
            <Activity className="h-4 w-4" />
            Workflows
          </TabsTrigger>

          <TabsTrigger value="config" className="flex items-center gap-1.5">
            <Settings className="h-4 w-4" />
            Config
          </TabsTrigger>

          <TabsTrigger value="logs" className="flex items-center gap-1.5">
            <Code className="h-4 w-4" />
            Logs
          </TabsTrigger>

          <TabsTrigger value="metrics" className="flex items-center gap-1.5">
            <Activity className="h-4 w-4" />
            Metrics
          </TabsTrigger>
        </TabsList>

        <TabsContent value="workflows" className="mt-6">
          {agent.type === "social-intel" ? (
            <SocialIntelWorkflowsView agentId={agent.id} />
          ) : (
            <div className="bg-muted/30 rounded-2xl p-12 text-center">
              <h3 className="text-lg font-medium mb-2">No workflows configured</h3>
              <p className="text-muted-foreground mb-6">
                This agent doesn't have any workflows configured yet.
              </p>
              <Button>Create Workflow</Button>
            </div>
          )}
        </TabsContent>

        <TabsContent value="config" className="mt-6">
          <div className="card-shadow p-5">
            <h3 className="font-medium mb-4">Agent Configuration</h3>
            <div className="bg-muted p-4 rounded-lg font-mono text-sm overflow-auto max-h-96">
              <pre>{JSON.stringify({
                "agent_name": agent.name,
                "version": agent.version,
                "api_keys": {
                  "openai": "sk-***************************",
                  "google": "AIza********************************"
                },
                "memory_limit_mb": 512,
                "timeout_seconds": 30,
                "retry_strategy": {
                  "max_attempts": 3,
                  "backoff_multiplier": 1.5
                },
                "logging_level": "INFO"
              }, null, 2)}</pre>
            </div>
          </div>
        </TabsContent>

        <TabsContent value="logs" className="mt-6">
          <div className="card-shadow p-5">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-medium">Agent Logs</h3>
              <Button variant="outline" size="sm">
                Refresh
              </Button>
            </div>
            <div className="bg-muted p-4 rounded-lg font-mono text-sm overflow-auto h-96">
              <div className="space-y-2">
                <p><span className="text-success">[INFO]</span> [2025-05-06 09:14:32] Agent started - version {agent.version}</p>
                <p><span className="text-primary">[DEBUG]</span> [2025-05-06 09:14:33] Loading configuration from environment</p>
                <p><span className="text-primary">[DEBUG]</span> [2025-05-06 09:14:33] Initializing API clients</p>
                <p><span className="text-success">[INFO]</span> [2025-05-06 09:14:35] Connected to message bus - queue lag: {agent.queueLag}</p>
                <p><span className="text-warning">[WARN]</span> [2025-05-06 09:14:36] Rate limit approaching for YouTube API: 85%</p>
                <p><span className="text-success">[INFO]</span> [2025-05-06 09:14:40] Starting workflow: Niche-Scout</p>
                <p><span className="text-primary">[DEBUG]</span> [2025-05-06 09:14:41] Fetching trending topics for: gaming, technology</p>
                <p><span className="text-primary">[DEBUG]</span> [2025-05-06 09:15:02] Processing data with semantic analysis</p>
                <p><span className="text-success">[INFO]</span> [2025-05-06 09:15:12] Workflow completed successfully</p>
                <p><span className="text-error">[ERROR]</span> [2025-05-06 09:16:05] HTTP 429: Rate limit exceeded for Twitter API</p>
                <p><span className="text-success">[INFO]</span> [2025-05-06 09:16:10] Retrying API request with backoff: 1.5s</p>
                <p><span className="text-success">[INFO]</span> [2025-05-06 09:16:12] API request successful after retry</p>
              </div>
            </div>
          </div>
        </TabsContent>

        <TabsContent value="metrics" className="mt-6">
          <div className="card-shadow p-5 h-96 flex items-center justify-center">
            <p className="text-muted-foreground">Metrics visualization coming soon</p>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
};

export default AgentDetailView;
