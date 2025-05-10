
import { useState } from "react";
import { format } from "date-fns";
import { 
  Download, 
  FileText,
  Star,
  StarOff,
  UploadCloud,
  Calendar,
  Bell,
  Link,
  Folder,
  ChartBar
} from "lucide-react";

import { Button } from "@/components/ui/button";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from "@/components/ui/table";
import StatusPill from "@/components/ui/StatusPill";
import { reports } from "@/data/reports";
import { Report, ReportType } from "@/types/reports";

const ReportsView = () => {
  const [activeTab, setActiveTab] = useState<ReportType>("all");
  const [starredReports, setStarredReports] = useState<string[]>(
    reports.filter(report => report.starred).map(report => report.id)
  );

  const filteredReports = reports.filter(report => {
    if (activeTab === "all") return true;
    return report.type === activeTab;
  });

  const handleToggleStar = (reportId: string) => {
    setStarredReports(prev => 
      prev.includes(reportId) 
        ? prev.filter(id => id !== reportId)
        : [...prev, reportId]
    );
  };

  const getStatusProps = (status: Report["status"]) => {
    switch (status) {
      case "success":
        return { status: "active" as const, label: "Success" };
      case "partial":
        return { status: "idle" as const, label: "Partial" };
      case "failed":
        return { status: "error" as const, label: "Failed" };
      default:
        return { status: "offline" as const, label: "Unknown" };
    }
  };

  const getActionButton = (report: Report) => {
    switch (report.action) {
      case "view":
        return (
          <Button variant="ghost" size="sm" asChild>
            <a href={report.actionHref || "#"}>View</a>
          </Button>
        );
      case "download":
        return (
          <Button variant="ghost" size="sm">
            <Download className="mr-1 h-4 w-4" />
            Download CSV
          </Button>
        );
      case "retry":
        return (
          <Button variant="ghost" size="sm">
            Retry
          </Button>
        );
      default:
        return null;
    }
  };

  return (
    <div className="container mx-auto space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold">Reports</h1>
          <p className="text-muted-foreground">
            Generate, access, and manage reports across various workflows and agent executions
          </p>
        </div>
        <div className="flex gap-2">
          <Button>
            <UploadCloud className="mr-2 h-4 w-4" />
            Upload Report
          </Button>
          <Button variant="outline">
            <Calendar className="mr-2 h-4 w-4" />
            Schedule Report
          </Button>
        </div>
      </div>

      <div className="flex items-center justify-between">
        <Tabs 
          defaultValue="all" 
          value={activeTab}
          onValueChange={(value) => setActiveTab(value as ReportType)}
          className="w-full"
        >
          <TabsList>
            <TabsTrigger value="all">
              <FileText className="mr-1 h-4 w-4" /> All Reports
            </TabsTrigger>
            <TabsTrigger value="workflow">
              <Link className="mr-1 h-4 w-4" /> Workflow Results
            </TabsTrigger>
            <TabsTrigger value="performance">
              <ChartBar className="mr-1 h-4 w-4" /> Agent Performance
            </TabsTrigger>
            <TabsTrigger value="error">
              <Bell className="mr-1 h-4 w-4" /> Error Logs
            </TabsTrigger>
            <TabsTrigger value="youtube">
              <FileText className="mr-1 h-4 w-4" /> YouTube Automation
            </TabsTrigger>
            <TabsTrigger value="custom">
              <Folder className="mr-1 h-4 w-4" /> Custom Uploads
            </TabsTrigger>
          </TabsList>

          <TabsContent value={activeTab}>
            <div className="rounded-md border mt-4">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="w-[200px]">Report Name</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Created On</TableHead>
                    <TableHead>Source Agent/Workflow</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredReports.map((report) => {
                    const { status, label } = getStatusProps(report.status);
                    const isStarred = starredReports.includes(report.id);

                    return (
                      <TableRow key={report.id}>
                        <TableCell className="font-medium">
                          <div className="flex items-center gap-2">
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-6 w-6"
                              onClick={() => handleToggleStar(report.id)}
                            >
                              {isStarred ? (
                                <Star className="h-4 w-4 text-yellow-500 fill-yellow-500" />
                              ) : (
                                <StarOff className="h-4 w-4" />
                              )}
                            </Button>
                            {report.name}
                          </div>
                        </TableCell>
                        <TableCell>{report.type.charAt(0).toUpperCase() + report.type.slice(1)}</TableCell>
                        <TableCell>{format(report.createdAt, "MMM d, yyyy")}</TableCell>
                        <TableCell>{report.source}</TableCell>
                        <TableCell>
                          <StatusPill status={status}>{label}</StatusPill>
                        </TableCell>
                        <TableCell className="text-right">
                          {getActionButton(report)}
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
};

export default ReportsView;
