
import { Link } from "react-router-dom";
import { useLocation } from "react-router-dom";
import { cn } from "@/lib/utils";
import { 
  Activity, 
  BarChart2, 
  Settings, 
  Users, 
  MessageSquare,
  Home,
  FileText,
  Layers,
  YoutubeIcon,
  PlusSquare
} from "lucide-react";

import {
  Sidebar as SidebarComponent,
  SidebarContent,
  SidebarFooter,
  SidebarMenu,
  SidebarMenuItem,
  SidebarMenuButton,
  useSidebar
} from "@/components/ui/sidebar";

// Import the Avatar component
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";

interface SidebarProps {
  logoUrl?: string;
  logoFallback?: string;
}

const Sidebar = ({ logoUrl = "/lovable-uploads/4f5a01e8-7502-47aa-9bb4-567065f7d751.png", logoFallback = "AP" }: SidebarProps) => {
  const location = useLocation();
  const { setOpen } = useSidebar();

  const isActive = (path: string) => {
    return location.pathname === path;
  };

  const handleMenuItemClick = () => {
    setOpen(true);
  };

  const navItems = [
    { 
      path: "/", 
      label: "Dashboard", 
      icon: Home 
    },
    { 
      path: "/agents", 
      label: "Agents", 
      icon: Users 
    },
    { 
      path: "/messages", 
      label: "Messages & Queues", 
      icon: MessageSquare 
    },
    { 
      path: "/analytics", 
      label: "Analytics", 
      icon: BarChart2 
    },
    { 
      path: "/reports", 
      label: "Reports", 
      icon: FileText 
    },
    { 
      path: "/taxonomy-settings", 
      label: "Taxonomy & Costs", 
      icon: Layers 
    },
    { 
      path: "/youtube-test", 
      label: "YouTube API Test", 
      icon: YoutubeIcon 
    },
    { 
      path: "/settings", 
      label: "Settings", 
      icon: Settings 
    },
  ];

  return (
    <SidebarComponent side="left" variant="sidebar" collapsible="icon">
      <SidebarContent className="pt-4">
        <SidebarMenu>
          <SidebarMenuItem>
            <Link to="/" aria-label="Alfred Dashboard" className="flex items-center justify-center w-full">
              <Avatar className="w-10 h-10">
                <AvatarImage src={logoUrl} alt="Alfred" />
                <AvatarFallback className="bg-primary text-white font-bold">{logoFallback}</AvatarFallback>
              </Avatar>
            </Link>
          </SidebarMenuItem>
          
          {navItems.map((item) => (
            <SidebarMenuItem key={item.path}>
              <SidebarMenuButton 
                asChild
                isActive={isActive(item.path)}
                tooltip={item.label}
              >
                <Link to={item.path} onClick={handleMenuItemClick}>
                  <item.icon />
                  <span>{item.label}</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
          ))}
        </SidebarMenu>
      </SidebarContent>

      <SidebarFooter className="mt-auto pb-4">
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton tooltip="Activity" onClick={handleMenuItemClick}>
              <Activity className="h-5 w-5" />
              <span>Activity</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </SidebarComponent>
  );
};

export default Sidebar;
