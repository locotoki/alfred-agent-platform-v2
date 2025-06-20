import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";

import { ThemeProvider } from "./components/theme/ThemeProvider";
import Shell from "./components/layout/Shell";
import DashboardView from "./components/dashboard/DashboardView";
import AgentsListView from "./components/agents/AgentsListView";
import AgentDetailView from "./components/agents/AgentDetailView";
import ReportsView from "./components/reports/ReportsView";
import NotFound from "./pages/NotFound";
import TaxonomySettings from "./pages/TaxonomySettings";
import YouTubeTest from "./pages/YouTubeTest";
import YouTubeTestOnly from "./pages/YouTubeTestOnly";
import GlobalNicheScoutWizard from "./components/wizards/GlobalNicheScoutWizard";
import { ChatPane } from "./features/chat/ChatPane";

// This stylesheet provides necessary CSS for the application
import "./index.css";

// Create a new QueryClient instance
const queryClient = new QueryClient();

const App = () => (
  <ThemeProvider defaultTheme="system" storageKey="alfred-theme">
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <Toaster />
        <Sonner />
        <BrowserRouter>
          <Shell>
            <GlobalNicheScoutWizard />
            <Routes>
              <Route path="/" element={<DashboardView />} />
              <Route path="/agents" element={<AgentsListView />} />
              <Route path="/agents/:agentId" element={<AgentDetailView />} />
              <Route path="/reports" element={<ReportsView />} />
              <Route path="/chat" element={<ChatPane />} />
              <Route path="/taxonomy-settings" element={<TaxonomySettings />} />
              <Route path="/youtube-test" element={<YouTubeTest />} />
              <Route path="/youtube-results" element={<YouTubeTestOnly />} />
              <Route path="*" element={<NotFound />} />
            </Routes>
          </Shell>
        </BrowserRouter>
      </TooltipProvider>
    </QueryClientProvider>
  </ThemeProvider>
);

export default App;
