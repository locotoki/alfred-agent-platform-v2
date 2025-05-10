
import { Search, Bell, ChevronDown, User, PanelRight, Youtube } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Link } from "react-router-dom";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { ThemeToggle } from "../theme/ThemeToggle";
import { SidebarTrigger, useSidebar } from "@/components/ui/sidebar";
import YouTubeResultsDialog from "@/components/ui/youtube-results-dialog";

const Topbar = () => {
  const { setOpen } = useSidebar();

  const handleSidebarToggle = () => {
    setOpen(true);
  };

  return (
    <header className="h-14 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/70 sticky top-0 z-20 border-b border-border flex items-center px-6">
      <div className="flex items-center flex-1">
        <SidebarTrigger onClick={handleSidebarToggle} className="mr-4" />
        
        <div className="relative max-w-2xl w-full">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
          <input
            type="search"
            placeholder="Search agents, workflows, logs..."
            className="w-full pl-10 pr-4 py-2 text-sm rounded-md bg-background border border-input h-9"
          />
        </div>
      </div>

      <div className="flex items-center space-x-4">
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="outline" className="text-sm gap-1">
              Production
              <ChevronDown className="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-40">
            <DropdownMenuItem>Production</DropdownMenuItem>
            <DropdownMenuItem>Staging</DropdownMenuItem>
            <DropdownMenuItem>Development</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
        
        {/* Direct Niche Scout Button */}
        <Button 
          variant="default" 
          className="text-sm"
          onClick={() => {
            // Create custom event to trigger the wizard
            const event = new CustomEvent('openNicheScoutWizard');
            window.dispatchEvent(event);
          }}
        >
          <Youtube className="h-4 w-4 mr-2" />
          Run Niche Scout
        </Button>
        
        {/* YouTube Results Dialog */}
        <YouTubeResultsDialog 
          trigger={
            <Button variant="outline" className="text-sm">
              <Youtube className="h-4 w-4 mr-2" />
              View Results
            </Button>
          } 
        />

        <Button variant="ghost" size="icon" className="relative">
          <Bell className="h-5 w-5" />
          <span className="absolute top-1 right-1 w-2 h-2 rounded-full bg-red-500"></span>
        </Button>

        <ThemeToggle />

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="outline" size="icon" className="rounded-full">
              <User className="h-5 w-5" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuLabel>My Account</DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem>Profile</DropdownMenuItem>
            <DropdownMenuItem>Settings</DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem>Log out</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
};

export default Topbar;
