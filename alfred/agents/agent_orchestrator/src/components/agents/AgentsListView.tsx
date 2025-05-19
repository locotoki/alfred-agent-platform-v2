
import { useMemo, useState } from "react";
import { Link } from "react-router-dom";
import StatusPill from "../ui/StatusPill";
import { agents } from "@/lib/data";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Plus } from "lucide-react";

const AgentsListView = () => {
  const [sortBy, setSortBy] = useState<keyof typeof agents[0]>("name");
  const [sortDirection, setSortDirection] = useState<"asc" | "desc">("asc");

  const sortedAgents = useMemo(() => {
    return [...agents].sort((a, b) => {
      if (sortBy === "name" || sortBy === "version" || sortBy === "status" || sortBy === "type") {
        return sortDirection === "asc"
          ? a[sortBy].localeCompare(b[sortBy])
          : b[sortBy].localeCompare(a[sortBy]);
      }

      if (sortBy === "lastTask") {
        const aValue = a[sortBy]?.getTime() || 0;
        const bValue = b[sortBy]?.getTime() || 0;
        return sortDirection === "asc" ? aValue - bValue : bValue - aValue;
      }

      // For queueLag or other number fields
      return sortDirection === "asc"
        ? (a[sortBy] as number) - (b[sortBy] as number)
        : (b[sortBy] as number) - (a[sortBy] as number);
    });
  }, [agents, sortBy, sortDirection]);

  const handleSort = (column: keyof typeof agents[0]) => {
    if (sortBy === column) {
      setSortDirection(sortDirection === "asc" ? "desc" : "asc");
    } else {
      setSortBy(column);
      setSortDirection("asc");
    }
  };

  const formatDate = (date: Date | null) => {
    if (!date) return "Never";

    const now = new Date();
    const diff = (now.getTime() - date.getTime()) / 1000; // in seconds

    if (diff < 60) return "Just now";
    if (diff < 3600) return `${Math.floor(diff / 60)} min ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)} hours ago`;

    return date.toLocaleDateString();
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold mb-1">Agents</h1>
          <p className="text-muted-foreground">Manage and monitor your AI agents</p>
        </div>

        <Button>
          <Plus className="mr-2 h-4 w-4" />
          New Agent
        </Button>
      </div>

      <div className="card-shadow rounded-2xl overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead className="w-[200px] cursor-pointer" onClick={() => handleSort("name")}>
                Name
              </TableHead>
              <TableHead className="cursor-pointer" onClick={() => handleSort("status")}>Status</TableHead>
              <TableHead className="cursor-pointer" onClick={() => handleSort("version")}>Version</TableHead>
              <TableHead className="cursor-pointer" onClick={() => handleSort("lastTask")}>Last Task</TableHead>
              <TableHead className="cursor-pointer" onClick={() => handleSort("queueLag")}>Queue Lag</TableHead>
              <TableHead>Type</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {sortedAgents.map((agent) => (
              <TableRow key={agent.id} className="cursor-pointer hover:bg-muted/50">
                <TableCell className="font-medium">
                  <Link to={`/agents/${agent.id}`} className="hover:text-primary transition-colors">
                    {agent.name}
                  </Link>
                </TableCell>
                <TableCell>
                  <StatusPill status={agent.status} />
                </TableCell>
                <TableCell>{agent.version}</TableCell>
                <TableCell>{formatDate(agent.lastTask)}</TableCell>
                <TableCell>
                  {agent.queueLag > 0 ? (
                    <span className={agent.queueLag > 100 ? "text-error" : ""}>
                      {agent.queueLag}
                    </span>
                  ) : (
                    <span className="text-muted-foreground">None</span>
                  )}
                </TableCell>
                <TableCell className="capitalize">{agent.type.replace("-", " ")}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
    </div>
  );
};

export default AgentsListView;
