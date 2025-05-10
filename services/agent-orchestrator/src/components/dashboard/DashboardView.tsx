import { Grid, Users, AlertTriangle, ArrowDownToLine } from "lucide-react";
import SummaryCard from "./SummaryCard";
import ChartGrid from "./ChartGrid";
import ActivityTimeline from "./ActivityTimeline";
import { FadeIn } from "../ui/animations/FadeIn";

const DashboardView = () => {
  return (
    <div className="space-y-6">
      <FadeIn direction="up" duration={400}>
        <div className="bg-gradient-primary-subtle p-6 rounded-lg mb-6">
          <h1 className="text-2xl font-bold mb-1 text-gradient-primary">Dashboard</h1>
          <p className="text-muted-foreground">Monitor and manage your AI agents</p>
        </div>
      </FadeIn>
      
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <FadeIn delay={100} direction="up">
          <SummaryCard
            title="Active Tasks"
            value="127"
            icon={<Grid className="h-5 w-5 text-primary" />}
            change={12}
            changeLabel="since yesterday"
            className="dashboard-card"
          />
        </FadeIn>
        
        <FadeIn delay={200} direction="up">
          <SummaryCard
            title="Agents"
            value="8"
            icon={<Users className="h-5 w-5 text-primary" />}
            change={0}
            changeLabel="no change"
            className="dashboard-card"
          />
        </FadeIn>
        
        <FadeIn delay={300} direction="up">
          <SummaryCard
            title="Errors (24h)"
            value="23"
            icon={<AlertTriangle className="h-5 w-5 text-primary" />}
            change={-5}
            changeLabel="since yesterday"
            className="dashboard-card card-gradient-error"
          />
        </FadeIn>
        
        <FadeIn delay={400} direction="up">
          <SummaryCard
            title="Queue Size"
            value="418"
            icon={<ArrowDownToLine className="h-5 w-5 text-primary" />}
            change={8}
            changeLabel="since an hour ago"
            className="dashboard-card"
          />
        </FadeIn>
      </div>
      
      <FadeIn delay={500} direction="up">
        <ChartGrid />
      </FadeIn>
      
      <FadeIn delay={600} direction="up">
        <ActivityTimeline />
      </FadeIn>
    </div>
  );
};

export default DashboardView;