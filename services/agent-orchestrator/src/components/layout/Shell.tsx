
import { ReactNode } from "react";
import Sidebar from "./Sidebar";
import Topbar from "./Topbar";
import { SidebarProvider, SidebarInset } from "@/components/ui/sidebar";

interface ShellProps {
  children: ReactNode;
  logoUrl?: string;
  logoFallback?: string;
}

const Shell = ({
  children,
  logoUrl = "/lovable-uploads/4f5a01e8-7502-47aa-9bb4-567065f7d751.png",
  logoFallback = "AP"
}: ShellProps) => {
  return (
    <SidebarProvider>
      <div className="min-h-screen flex w-full">
        <Sidebar logoUrl={logoUrl} logoFallback={logoFallback} />
        <SidebarInset className="flex flex-col">
          <Topbar />
          <main className="flex-1 p-6">
            {children}
          </main>
        </SidebarInset>
      </div>
    </SidebarProvider>
  );
};

export default Shell;
