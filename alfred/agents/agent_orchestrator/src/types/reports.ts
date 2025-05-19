
export type ReportStatus = "success" | "partial" | "failed";

export type ReportType =
  | "all"
  | "workflow"
  | "performance"
  | "error"
  | "youtube"
  | "custom";

export interface Report {
  id: string;
  name: string;
  type: ReportType;
  createdAt: Date;
  source: string;
  status: ReportStatus;
  action: "view" | "download" | "retry";
  actionHref?: string;
  starred?: boolean;
}
